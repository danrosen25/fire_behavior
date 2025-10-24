  module mpi_mod

    implicit none

    private

    public :: Calc_tasks_in_x_and_y, Calc_patch_dims, Gather_var2d, Do_halo_exchange, Do_halo_exchange_with_corners

  contains

    subroutine Calc_patch_dims (nx, ny, px, py, coords, istart, iend, jstart, jend)

      implicit none

      integer, intent (in) :: nx, ny, px, py
      integer, dimension(2) :: coords
      integer, intent (out) :: istart, iend, jstart, jend

      integer :: nx_local, ny_local, x, y, rx, ry


      x = coords(1)
      y = coords(2)

      rx = mod(nx, px)
      ry = mod(ny, py)

        ! size patch
      nx_local = nx / px
      if (x < rx) nx_local = nx_local + 1

      ny_local = ny / py
      if (y < ry) ny_local = ny_local + 1

        ! coords in the grid
      istart = (nx / px) * x + min(x, rx) + 1
      iend = istart + nx_local - 1

      jstart = (ny / py) * y + min(y, ry) + 1
      jend = jstart + ny_local - 1

    end subroutine Calc_patch_dims

    pure subroutine Calc_tasks_in_x_and_y (ntasks, nx, ny, px, py)

      implicit none

      integer, intent (in)  :: ntasks, nx, ny
      integer, intent (out) :: px, py

      integer :: i, j
      real    :: best_ratio, this_ratio, target_ratio,ratio


      best_ratio = huge (best_ratio)
      target_ratio = real (nx) / real (ny)

      px = 1
      py = ntasks

      do i = 1, ntasks
        if (mod (ntasks, i) == 0) then
          j = ntasks / i
          ratio = real (i) / real (j)
          this_ratio = abs (ratio - target_ratio)

          if (this_ratio < best_ratio) then
            best_ratio = this_ratio
            px = i
            py = j
          end if
        end if
      end do

    end subroutine Calc_tasks_in_x_and_y

    subroutine Do_halo_exchange (patch, ims, ime, jms, jme, ips, ipe, jps, jpe, nghost, cart_comm)

    ! It does not update the corners in the halo

#ifdef DM_PARALLEL
      use mpi
#endif

      implicit none

      integer, intent (in) :: cart_comm, ims, ime, jms, jme, ips, ipe, jps, jpe, nghost
      real, dimension(ims:ime, jms:jme), intent (in out) :: patch

      integer :: ierr, nbr_left, nbr_right, nbr_up, nbr_down, tag_base, nx, ny
      integer, dimension(8) :: reqs
      real, dimension(:), allocatable :: sendbuf_right, recvbuf_left, sendbuf_left, recvbuf_right, &
                                         sendbuf_up, recvbuf_down, sendbuf_down, recvbuf_up

      integer :: rank, i, j, k
      integer, dimension(2) :: coords


#ifdef DM_PARALLEL
      call MPI_Comm_rank(cart_comm, rank, ierr)
      call MPI_Cart_coords(cart_comm, rank, 2, coords, ierr)

      nx = ipe - ips + 1
      ny = jpe - jps + 1

      tag_base = 1000

        ! Get neighbor ranks in Cartesian topology
      call MPI_Cart_shift(cart_comm, 0, 1, nbr_left, nbr_right, ierr)
      call MPI_Cart_shift(cart_comm, 1, 1, nbr_down, nbr_up, ierr)

        ! Allocate buffers
      allocate (sendbuf_right(ny * nghost), recvbuf_left(ny * nghost))
      allocate (sendbuf_left(ny * nghost), recvbuf_right(ny * nghost))
      allocate (sendbuf_up(nx * nghost), recvbuf_down(nx * nghost))
      allocate (sendbuf_down(nx * nghost), recvbuf_up(nx * nghost))

        ! Send RIGHT, receive LEFT
      k = 0
      do j = jps, jpe
        do i = ipe - nghost + 1, ipe
          k = k + 1
          sendbuf_right(k) = patch(i, j)
        end do
      end do
      call MPI_Irecv(recvbuf_left, ny*nghost, MPI_REAL, nbr_left, tag_base + 0, cart_comm, reqs(1), ierr)
      call MPI_Isend(sendbuf_right, ny*nghost, MPI_REAL, nbr_right, tag_base + 0, cart_comm, reqs(2), ierr)

      ! Send LEFT, receive RIGHT
      k = 0
      do j = jps, jpe
        do i = ips, ips + nghost - 1
          k = k + 1
          sendbuf_left(k) = patch(i, j)
        end do
      end do
      call MPI_Irecv (recvbuf_right, ny * nghost, MPI_REAL, nbr_right, tag_base + 1, cart_comm, reqs(3), ierr)
      call MPI_Isend (sendbuf_left, ny * nghost, MPI_REAL, nbr_left, tag_base + 1, cart_comm, reqs(4), ierr)

        ! Send UP, receive DOWN
      k = 0
      do j = jpe - nghost + 1, jpe
        do i = ips, ipe
          k = k + 1
          sendbuf_up(k) = patch(i, j)
        end do
      end do
      call MPI_Irecv (recvbuf_down, nx * nghost, MPI_REAL, nbr_down, tag_base + 2, cart_comm, reqs(5), ierr)
      call MPI_Isend (sendbuf_up, nx * nghost, MPI_REAL, nbr_up, tag_base + 2, cart_comm, reqs(6), ierr)

      ! Send DOWN, receive UP
      k = 0
      do j = jps, jps + nghost - 1
        do i = ips, ipe
          k = k + 1
          sendbuf_down(k) = patch(i, j)
        end do
      end do
      call MPI_Irecv(recvbuf_up, nx * nghost, MPI_REAL, nbr_up, tag_base + 3, cart_comm, reqs(7), ierr)
      call MPI_Isend(sendbuf_down, nx * nghost, MPI_REAL, nbr_down, tag_base + 3, cart_comm, reqs(8), ierr)

       ! Wait for all communications
      call MPI_Waitall(8, reqs, MPI_STATUSES_IGNORE, ierr)

        ! Unpack ghost zones
        ! LEFT ghost
      if (nbr_left /= MPI_PROC_NULL) then
        k = 0
        do j = jps, jpe
          do i = ips - nghost, ips - 1
            k = k + 1
            patch(i, j) = recvbuf_left(k)
          end do
        end do
      end if

        ! RIGHT ghost
      if (nbr_right /= MPI_PROC_NULL) then
        k = 0
        do j = jps, jpe
          do i = ipe + 1, ipe + nghost
            k = k + 1
            patch(i, j) = recvbuf_right(k)
          end do
        end do
      end if

        ! UP ghost (top halo rows)
      if (nbr_up /= MPI_PROC_NULL) then
        k = 0
        do j = jpe + 1, jpe + nghost
          do i = ips, ipe
            k = k + 1
            patch(i, j) = recvbuf_up(k)
          end do
        end do
      end if

        ! DOWN ghost (bottom halo rows)
      if (nbr_down /= MPI_PROC_NULL) then
        k = 0
        do j = jps - nghost, jps - 1
          do i = ips, ipe
            k = k + 1
            patch(i, j) = recvbuf_down(k)
          end do
        end do
      end if

        ! Deallocate buffers
      deallocate (sendbuf_right, recvbuf_left)
      deallocate (sendbuf_left, recvbuf_right)
      deallocate (sendbuf_up, recvbuf_down)
      deallocate (sendbuf_down, recvbuf_up)

#endif

    end subroutine Do_halo_exchange


    subroutine Do_halo_exchange_with_corners (patch, ims, ime, jms, jme, ips, ipe, jps, jpe, nghost, cart_comm)

#ifdef DM_PARALLEL
      use mpi
#endif

      implicit none

      integer, intent (in) :: cart_comm, ims, ime, jms, jme, ips, ipe, jps, jpe, nghost
      real, dimension(ims:ime, jms:jme), intent (inout) :: patch

      integer :: ierr, nbr_left, nbr_right, nbr_up, nbr_down, tag_base
      integer :: nx, ny, rank, i, j, k
      integer, dimension(8) :: reqs
      integer, dimension(2) :: coords
      real, dimension(:), allocatable :: sendbuf_right, recvbuf_left, sendbuf_left, recvbuf_right
      real, dimension(:), allocatable :: sendbuf_up, recvbuf_down, sendbuf_down, recvbuf_up


#ifdef DM_PARALLEL
      call MPI_Comm_rank(cart_comm, rank, ierr)
      call MPI_Cart_coords(cart_comm, rank, 2, coords, ierr)

      nx = ipe - ips + 1
      ny = jpe - jps + 1
      tag_base = 1000

        ! Neighbor ranks
      call MPI_Cart_shift (cart_comm, 0, 1, nbr_left, nbr_right, ierr)
      call MPI_Cart_shift (cart_comm, 1, 1, nbr_down, nbr_up, ierr)

        ! Halo exchange in X direction
      allocate (sendbuf_right(ny * nghost), recvbuf_left(ny * nghost))
      allocate (sendbuf_left(ny * nghost), recvbuf_right(ny * nghost))

        ! Pack right send buffer
      k = 0
      do j = jps, jpe
        do i = ipe - nghost + 1, ipe
          k = k + 1
          sendbuf_right(k) = patch(i, j)
        end do
      end do

        ! Pack left send buffer
      k = 0
      do j = jps, jpe
        do i = ips, ips + nghost - 1
          k = k + 1
          sendbuf_left(k) = patch(i, j)
        end do
      end do

        ! Exchange left/right
      call MPI_Irecv (recvbuf_left, ny * nghost, MPI_REAL, nbr_left, tag_base + 0, cart_comm, reqs(1), ierr)
      call MPI_Isend (sendbuf_right, ny * nghost, MPI_REAL, nbr_right, tag_base + 0, cart_comm, reqs(2), ierr)
      call MPI_Irecv (recvbuf_right, ny * nghost, MPI_REAL, nbr_right, tag_base + 1, cart_comm, reqs(3), ierr)
      call MPI_Isend (sendbuf_left, ny * nghost, MPI_REAL, nbr_left, tag_base + 1, cart_comm, reqs(4), ierr)

      call MPI_Waitall (4, reqs, MPI_STATUSES_IGNORE, ierr)

        ! Unpack left halo
      if (nbr_left /= MPI_PROC_NULL) then
        k = 0
        do j = jps, jpe
          do i = ips - nghost, ips - 1
            k = k + 1
            patch(i, j) = recvbuf_left(k)
          end do
        end do
      end if

        ! Unpack right halo
      if (nbr_right /= MPI_PROC_NULL) then
        k = 0
        do j = jps, jpe
          do i = ipe + 1, ipe + nghost
            k = k + 1
            patch(i, j) = recvbuf_right(k)
          end do
        end do
      end if

      deallocate (sendbuf_right, recvbuf_left, sendbuf_left, recvbuf_right)

        ! Exchange in Y direction (including halos in X direction)
      allocate (sendbuf_up((nx + 2 * nghost) * nghost), recvbuf_down((nx + 2 * nghost) * nghost))
      allocate (sendbuf_down((nx + 2 * nghost) * nghost), recvbuf_up((nx + 2 * nghost) * nghost))

        ! Pack up send buffer
      k = 0
      do j = jpe - nghost + 1, jpe
        do i = ips - nghost, ipe + nghost
          k = k + 1
          sendbuf_up(k) = patch(i, j)
        end do
      end do

        ! Pack down send buffer
      k = 0
      do j = jps, jps + nghost - 1
        do i = ips - nghost, ipe + nghost
          k = k + 1
          sendbuf_down(k) = patch(i, j)
        end do
      end do

        ! Exchange up/down
      call MPI_Irecv (recvbuf_down, (nx + 2 * nghost) * nghost, MPI_REAL, nbr_down, tag_base + 2, cart_comm, reqs(1), ierr)
      call MPI_Isend (sendbuf_up, (nx + 2 * nghost) * nghost, MPI_REAL, nbr_up, tag_base + 2, cart_comm, reqs(2), ierr)
      call MPI_Irecv (recvbuf_up, (nx + 2 * nghost) * nghost, MPI_REAL, nbr_up, tag_base + 3, cart_comm, reqs(3), ierr)
      call MPI_Isend (sendbuf_down, (nx + 2 * nghost) * nghost, MPI_REAL, nbr_down, tag_base + 3, cart_comm, reqs(4), ierr)

      call MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE, ierr)

        ! Unpack down halo
      if (nbr_down /= MPI_PROC_NULL) then
        k = 0
        do j = jps - nghost, jps - 1
          do i = ips - nghost, ipe + nghost
            k = k + 1
            patch(i, j) = recvbuf_down(k)
          end do
        end do
      end if

        ! Unpack up halo
      if (nbr_up /= MPI_PROC_NULL) then
        k = 0
        do j = jpe + 1, jpe + nghost
          do i = ips - nghost, ipe + nghost
            k = k + 1
            patch(i, j) = recvbuf_up(k)
          end do
        end do
      end if

      deallocate (sendbuf_up, recvbuf_down, sendbuf_down, recvbuf_up)
#endif

    end subroutine Do_halo_exchange_with_corners

    subroutine Gather_var2d (nx, ny, ifps, ifpe, jfps, jfpe, var2d_local, var2d_global)

#ifdef DM_PARALLEL
      use mpi_f08
#endif

      implicit none

      integer, intent (in) :: nx, ny, ifps, ifpe, jfps, jfpe
      real, dimension(ifps:ifpe, jfps:jfpe), intent (in) :: var2d_local
      real, dimension(nx, ny), intent (out) :: var2d_global

      real, dimension(:, :), allocatable :: buf
      integer :: rank, ierr, ntasks, src, i_start, j_start, nx_local, ny_local, nxl, nyl

      integer, dimension(4) :: metadata


#ifdef DM_PARALLEL
      call Mpi_comm_size (MPI_COMM_WORLD, ntasks, ierr)
      call Mpi_comm_rank (MPI_COMM_WORLD, rank, ierr)

      nx_local = ifpe - ifps + 1
      ny_local = jfpe - jfps + 1
      if (rank /= 0) then
        metadata = [ifps, jfps, nx_local, ny_local]
        call Mpi_Send (metadata, 4, MPI_INTEGER, 0, 200, MPI_COMM_WORLD, ierr)
        call Mpi_Send (var2d_local, nx_local * ny_local, MPI_REAL, 0, 100, MPI_COMM_WORLD, ierr)
      else
          ! Rank 0 places its own data
        var2d_global(ifps:ifpe, jfps:jfpe) = var2d_local

          ! Receive from others
        do src = 1, ntasks - 1
            ! Receive metadata
          call Mpi_Recv (metadata, 4, MPI_INTEGER, src, 200, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
          i_start = metadata(1)
          j_start = metadata(2)
          nxl = metadata(3)
          nyl = metadata(4)
          allocate (buf(nxl, nyl))
          call Mpi_Recv (buf, nxl * nyl, MPI_REAL, src, 100, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)

            ! Place in global array
          var2d_global(i_start:i_start + nxl - 1, j_start:j_start + nyl - 1) = buf

          deallocate (buf)
        end do
      end if
#endif

    end subroutine Gather_var2d

  end module mpi_mod
