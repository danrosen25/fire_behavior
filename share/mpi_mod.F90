  module mpi_mod

    implicit none

    private

    public :: Calc_tasks_in_x_and_y, Calc_patch_dims, Gather_var2d

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
