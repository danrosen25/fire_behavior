  module coupling_mod

    use proj_lc_mod, only : proj_lc_t
    use interp_mod, only : Interp_horizontal_nearest, Interp_horizontal_bilinear, HINTERP_NEAREST, HINTERP_BILINEAR
    use stderrout_mod, only : Stop_simulation


    implicit none

    private

    public :: Interp_horizontal

  contains

    subroutine Interp_horizontal (data_in, proj_data_in, ims, ime, jms, jme, ifms, ifme, jfms, jfme, &
        num_tiles, i_start, i_end, j_start, j_end, hinterp_opt, lats_out, lons_out, data_out)

      implicit none

      type (proj_lc_t), intent (in) :: proj_data_in
      integer, intent (in) :: ifms, ifme, jfms, jfme, ims, ime, jms, jme, num_tiles, hinterp_opt
      integer, dimension (num_tiles), intent (in) :: i_start, i_end, j_start, j_end
      real, dimension(ims:ime, jms:jme), intent (in) :: data_in
      real, dimension (ifms:ifme, jfms:jfme), intent (in) :: lats_out, lons_out
      real, dimension (ifms:ifme, jfms:jfme), intent (in out) :: data_out

      integer :: ij, ifts, ifte, jfts, jfte


      Hinterp: select case (hinterp_opt)
        case (HINTERP_NEAREST)
          !$OMP PARALLEL DO   &
          !$OMP PRIVATE (ij, ifts, ifte, jfts, jfte)
          do ij = 1, num_tiles
            ifts = i_start(ij)
            ifte = i_end(ij)
            jfts = j_start(ij)
            jfte = j_end(ij)
            call Interp_horizontal_nearest (data_in, proj_data_in, ims, ime, jms, jme, ifms, ifme, jfms, jfme, ifts, ifte, jfts, jfte, &
                lats_out, lons_out, data_out)
          end do
          !$OMP END PARALLEL DO

        case (HINTERP_BILINEAR)
          !$OMP PARALLEL DO   &
          !$OMP PRIVATE (ij, ifts, ifte, jfts, jfte)
          do ij = 1, num_tiles
            ifts = i_start(ij)
            ifte = i_end(ij)
            jfts = j_start(ij)
            jfte = j_end(ij)
            call Interp_horizontal_bilinear (data_in, proj_data_in, ims, ime, jms, jme, ifms, ifme, jfms, jfme, ifts, ifte, jfts, jfte, &
                lats_out, lons_out, data_out)
          end do
          !$OMP END PARALLEL DO

        case default
          call Stop_simulation ('The horizontal interpolation option selected does not exist.')

      end select Hinterp

    end subroutine Interp_horizontal

  end module coupling_mod
