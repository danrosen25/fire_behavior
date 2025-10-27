  module initialize_mod

    use state_mod, only : state_fire_t
    use namelist_mod, only : namelist_t
    use geogrid_mod, only : geogrid_t
    use wrf_mod, only : wrf_t
    use fire_driver_mod, only : Init_fire_components
    use stderrout_mod, only: Print_message

    private

    public :: Init_fire_state, Init_atm_state, Init_fire_state_within_wrf

  contains

    subroutine Init_atm_state (atm_state, config_flags)

      implicit none

      type (wrf_t), intent (in out) :: atm_state
      type (namelist_t), intent (in) :: config_flags

      logical, parameter :: DEBUG_LOCAL = .false.


      if (DEBUG_LOCAL) call Print_message ('  Entering subroutine Init_atm_state')

      atm_state = wrf_t ('wrf.nc', config_flags)

      if (DEBUG_LOCAL) call Print_message ('  Leaving subroutine Init_atm_state')

    end subroutine Init_atm_state

    subroutine Init_fire_state (grid, config_flags, wrf)

#ifdef DM_PARALLEL
      use mpi_f08
#endif

      implicit none

      type (state_fire_t), intent (in out) :: grid
      type (namelist_t), intent (in) :: config_flags
      type (wrf_t), intent (in out), optional :: wrf

      type (geogrid_t) :: geogrid
      logical, parameter :: DEBUG_LOCAL = .false.
      integer :: i, j, unit_out, unit_out2

      integer :: rank, ierr


      if (DEBUG_LOCAL) call Print_message ('  Entering subroutine Init_state')

      if (DEBUG_LOCAL) call Print_message ('  Initialization...')
      if (config_flags%ideal_opt == 0) then
          ! Real world
        if (DEBUG_LOCAL) call Print_message ('    Reading geogrid file')
#ifdef DM_PARALLEL
        call Mpi_comm_rank (MPI_COMM_WORLD, rank, ierr)
#else
        rank = 0
#endif

        if (rank == 0) geogrid = geogrid_t (file_name = 'geo_em.d01.nc')

#ifdef DM_PARALLEL
        call MPI_Bcast (geogrid%cen_lon, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%cen_lat, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%dx, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%dy, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%true_lat_1, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%true_lat_2, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast (geogrid%stand_lon, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)

        call MPI_Bcast(geogrid%map_proj, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%sr_x, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%sr_y, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%ifds, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%ifde, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%jfds, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
        call MPI_Bcast(geogrid%jfde, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
#endif

        if (DEBUG_LOCAL) call Print_message ('    Initializing fire state')
        call grid%Initialization (config_flags, geogrid)

        if (present (wrf)) then
          if (DEBUG_LOCAL) call Print_message ('    Initializing atmospheric state')
          call grid%Handle_wrfdata_update (wrf, config_flags)
        end if
      else
          ! Ideal
        if (DEBUG_LOCAL) call Print_message ('    Initializing fire state')
        call grid%Initialization (config_flags)
      end if

      call Init_fire_components (grid, config_flags)

      if (DEBUG_LOCAL) then
          ! print lat/lons
        open (newunit = unit_out, file = 'latlons_c.dat')
        open (newunit = unit_out2, file = 'latlons.dat')
        do j = 1, grid%ny + 1
          do i = 1, grid%nx + 1
            write (unit_out, *) grid%lons_c(i, j), grid%lats_c(i, j)
            if (i /= grid%nx + 1 .and. j /= grid%ny + 1) write (unit_out2, *) grid%lons(i, j), grid%lats(i, j)
          end do
        end do
        close (unit_out)
        close (unit_out2)

        if (present (wrf)) then
          open (newunit = unit_out, file = 'wrf_latlons_atm.dat')
          do j = 1, wrf%jde - 1
            do i = 1, wrf%ide - 1
              write (unit_out, *) wrf%lons(i, j), wrf%lats(i, j)
            end do
          end do
          close (unit_out)
        end if
      end if

      if (DEBUG_LOCAL) call Print_message ('  Leaving subroutine Init_state')

    end subroutine Init_fire_state

    subroutine Init_fire_state_within_wrf (state, config_flags, &
        ifds, ifde, ifms, ifme, ifps, ifpe, &
        jfds, jfde, jfms, jfme, jfps, jfpe, &
        kfds, kfde, kfms, kfme, kfps, kfpe, &
        kfts, kfte, ide, jde, dx, dy, sr_x, sr_y, &
        map_proj, cen_lat, cen_lon, truelat1, truelat2, stand_lon, &
        nfuel_cat, zsf, dzdxf, dzdyf)

      implicit none

      type (state_fire_t), intent (in out) :: state
      type (namelist_t), intent (in) :: config_flags
      integer, intent (in) :: ifds, ifde, ifms, ifme, ifps, ifpe, &
                              jfds, jfde, jfms, jfme, jfps, jfpe, &
                              kfds, kfde, kfms, kfme, kfps, kfpe, &
                              kfts, kfte, map_proj, sr_x, sr_y, ide, jde
      real :: dx, dy, cen_lat, cen_lon, truelat1, truelat2, stand_lon
      real, dimension(ifms:ifme, jfms:jfme), intent (in) :: nfuel_cat, zsf, dzdxf, dzdyf


      call state%Initialization (config_flags, &
          ifds = ifds, ifde = ifde, ifms = ifms, ifme = ifme, ifps = ifps, ifpe = ifpe, &
          jfds = jfds, jfde = jfde, jfms = jfms, jfme = jfme, jfps = jfps, jfpe = jfpe, &
          kfds = kfds, kfde = kfde, kfms = kfms, kfme = kfme, kfps = kfps, kfpe = kfpe, &
          kfts = kfts, kfte = kfte, ide = ide, jde = jde, &
          cen_lat = cen_lat, cen_lon = cen_lon, truelat1 = truelat1, &
          truelat2 = truelat2, stand_lon = stand_lon, dx = dx, dy = dy, sr_x = sr_x, sr_y = sr_y, &
          nfuel_cat = nfuel_cat, zsf = zsf, dzdxf = dzdxf, dzdyf = dzdyf)

      call Init_fire_components (state, config_flags)

    end subroutine Init_fire_state_within_wrf

  end module initialize_mod
