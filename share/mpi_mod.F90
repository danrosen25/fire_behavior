  module mpi_mod

    implicit none

    private

    public :: Calc_tasks_in_x_and_y, Calc_patch_dims

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

  end module mpi_mod
