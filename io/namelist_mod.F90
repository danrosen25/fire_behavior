  module namelist_mod

#ifdef DM_PARALLEL
    use mpi_f08
#endif
    use stderrout_mod, only : Stop_simulation, Print_message

    implicit none

    private

    public :: namelist_t, FIRE_MAX_IGNITIONS_IN_NAMELIST

    integer, parameter :: FIRE_MAX_IGNITIONS_IN_NAMELIST = 5
      ! Default ideal block
    real, parameter :: DX_DEFAULT = 100.0, U_DEFAULT = 5.0, V_DEFAULT = 0.0, LAT_DEFAULT = 40.3636, LON_DEFAULT = -4.4035, &
       DZ_DX_DEFAULT = 0.0, ELEVATION_DEFAULT = 0.0
    integer, parameter :: IDEAL_OPT_DEFAULT = 0, NX_DEFAULT = 100, FUEL_CAT_DEFAULT = 1
      ! Default options
    integer, parameter :: NO_FMC_MODEL = -1

    type :: namelist_t
      integer :: start_year = -1, start_month = -1, start_day = -1, start_hour = -1, start_minute = -1, start_second = -1, &
          end_year = -1, end_month = -1, end_day = -1, end_hour = -1, end_minute = -1, end_second = -1, interval_output = -1, &
          interval_atm = -1
      real :: dt = 2.0

      integer :: num_tiles = 1
      integer :: tile_strategy = 0

      integer :: fire_print_msg = 0           ! "write fire statistics, 0 no writes, 1+ for more"  ""
      real :: fire_atm_feedback = 1.0         ! "the heat fluxes to the atmosphere are multiplied by this" "1"
      logical :: fire_is_real_perim = .false. ! .false. = point/line ignition, .true. = observed perimeter"

      integer :: fire_upwinding = 9           ! "upwind normal spread: 1=standard, 2=godunov, 3=eno, 4=sethian, 5=2nd-order,
                                              ! 6=WENO3, 7=WENO5, 8=hybrid WENO3/ENO1, 9=hybrid WENO5/ENO1" "1"
      real :: fire_viscosity = 0.4            ! artificial viscosity in level set method farm from near-front region
      real :: fire_viscosity_bg = 0.4         ! artificial viscosity in level set method the near-front region. Should be lower/equal to fire_viscosity
      integer :: fire_viscosity_ngp = 2       ! number of grid points around lfn=0 where fire_viscosity_bg is used. Defines the near front region
      real :: fire_viscosity_band = 0.5       ! number of times the near front region, used to transition from fire_viscosity_bg to fire_viscosity

      logical :: fire_lsm_reinit = .true.     ! "flag to activate reinitialization of level set method"
      integer :: fire_lsm_reinit_iter = 1     ! "number of iterations for the reinitialization PDE"
      integer :: fire_upwinding_reinit = 4    ! "numerical scheme (space) for reinitialization PDE: 1=WENO3, 2=WENO5, 3=hybrid WENO3-ENO1, 4=hybrid WENO5-ENO1"
      integer :: fire_lsm_band_ngp = 4        ! "number of grid points around lfn=0 that WENO5/3 is used (ENO1 elsewhere),
                                              ! for fire_upwinding_reinit=4,5 and fire_upwinding=8,9 options"

      real :: fire_wind_height = 6.096        ! "height of uah,vah wind in fire spread formula" "m"
      integer :: wind_vinterp_opt = 0         ! "wind (adjustment factor) interpolation option"
      logical :: fire_lsm_zcoupling = .false. ! "flag to activate reference velocity at a different height from fire_wind_height"
      real :: fire_lsm_zcoupling_ref = 50.0   ! "reference height from wich u at fire_wind_hegiht is calculated using a logarithmic profile" "m"

      real :: frac_fburnt_to_smoke = 0.02        ! "parts per unit of burned fuel becoming smoke" "g_smoke/kg_air"
      real :: fuelmc_g = 0.08                 ! Fuel moisture content ground (Dead FMC)
      real :: fuelmc_g_live = 0.30            ! Fuel moisture content ground (Live FMC). 30% Completely cured, treat as dead fuel
      real :: fuelmc_c = 1.00                 ! Fuel moisture content canopy

      logical :: fmoist_run = .false.         ! run moisture model
      integer :: fmoist_freq = 0              ! frequency to run moisture model 0: use fmoist_dt, k>0: every k timesteps
      real :: fmoist_dt = 600.0               ! moisture model time step [s]

      integer :: ideal_opt = IDEAL_OPT_DEFAULT  ! 0) real world, 1) ideal

        ! Objects
      integer :: fuel_opt = 1 ! Fuel model
      integer :: ros_opt = 0  ! ROS parameterization
      integer :: fmc_opt = NO_FMC_MODEL ! FMC model
      integer :: emis_opt = 0 ! Object to be added. 0) WRF-Fire emiss, 1) PM2.5 as a function of FMC

        ! Ignitions
      integer :: fire_num_ignitions = 0 ! "number of ignition lines"

      real :: fire_ignition_start_lon1 = 0.0  ! "long coord of start of ignition line" "deg"
      real :: fire_ignition_start_lat1 = 0.0  ! "lat coord of start of ignition line" "deg"
      real :: fire_ignition_end_lon1 = 0.0    ! "long coord of end of ignition line" "deg"
      real :: fire_ignition_end_lat1 = 0.0    ! "lat coord of end of ignition line" "deg"
      real :: fire_ignition_ros1 = 0.01       ! "rate of spread during ignition" "m/s"
      real :: fire_ignition_start_time1 = 0.0 ! "ignition line start time" "s"
      real :: fire_ignition_end_time1 = 0.0   ! "ignition line end time" "s"
      real :: fire_ignition_radius1 = 0.0     ! "ignite all within the radius" "m"

      real :: fire_ignition_start_lon2 = 0.0
      real :: fire_ignition_start_lat2 = 0.0
      real :: fire_ignition_end_lon2 = 0.0
      real :: fire_ignition_end_lat2 = 0.0
      real :: fire_ignition_ros2 = 0.01
      real :: fire_ignition_start_time2 = 0.0
      real :: fire_ignition_end_time2 = 0.0
      real :: fire_ignition_radius2 = 0.0

      real :: fire_ignition_start_lon3 = 0.0
      real :: fire_ignition_start_lat3 = 0.0
      real :: fire_ignition_end_lon3 = 0.0
      real :: fire_ignition_end_lat3 = 0.0
      real :: fire_ignition_ros3 = 0.01
      real :: fire_ignition_start_time3 = 0.0
      real :: fire_ignition_end_time3 = 0.0
      real :: fire_ignition_radius3 = 0.0

      real :: fire_ignition_start_lon4 = 0.0
      real :: fire_ignition_start_lat4 = 0.0
      real :: fire_ignition_end_lon4 = 0.0
      real :: fire_ignition_end_lat4 = 0.0
      real :: fire_ignition_ros4 = 0.01
      real :: fire_ignition_start_time4 = 0.0
      real :: fire_ignition_end_time4 = 0.0
      real :: fire_ignition_radius4 = 0.0

      real :: fire_ignition_start_lon5 = 0.0
      real :: fire_ignition_start_lat5 = 0.0
      real :: fire_ignition_end_lon5 = 0.0
      real :: fire_ignition_end_lat5 = 0.0
      real :: fire_ignition_ros5 = 0.01
      real :: fire_ignition_start_time5 = 0.0
      real :: fire_ignition_end_time5 = 0.0
      real :: fire_ignition_radius5 = 0.0

        ! Ideal block
      real :: dx = DX_DEFAULT
      real :: dy = DX_DEFAULT
      integer :: nx = NX_DEFAULT
      integer :: ny = NX_DEFAULT

      real :: zonal_wind = U_DEFAULT
      real :: meridional_wind = V_DEFAULT
      integer :: fuel_cat = FUEL_CAT_DEFAULT
      real :: dz_dx = DZ_DX_DEFAULT
      real :: dz_dy = DZ_DX_DEFAULT
      real :: elevation = ELEVATION_DEFAULT

      real :: cen_lat = LAT_DEFAULT
      real :: cen_lon = LON_DEFAULT
      real :: stand_lon = LON_DEFAULT
      real :: true_lat_1 = LAT_DEFAULT
      real :: true_lat_2 = LAT_DEFAULT

        ! Atmosphere
      integer :: kds = 1, kde = 1
    contains
      procedure, public :: Broadcast_nml => Broadcast_nml
      procedure, public :: Check_nml => Check_nml
      procedure, public :: Initialization => Init_namelist
      procedure, public :: Init_fire_block => Init_fire_block
      procedure, public :: Init_ideal_block => Init_ideal_block
      procedure, public :: Init_time_block => Init_time_block
      procedure, public :: Init_atm_block => Init_atm_block_legacy
    end type namelist_t

  contains

    subroutine Broadcast_nml (this)

      implicit none

      class (namelist_t), intent (in out) :: this


#ifdef DM_PARALLEL

        ! Fire block
      call Broadcast_integer (this%fire_print_msg)
      call Broadcast_real (this%fire_atm_feedback)
      call Broadcast_integer (this%fire_upwinding)
      call Broadcast_real (this%fire_viscosity)
      call Broadcast_logical (this%fire_lsm_reinit)
      call Broadcast_integer (this%fire_lsm_reinit_iter)
      call Broadcast_integer (this%fire_upwinding_reinit)
      call Broadcast_integer (this%fire_lsm_band_ngp)
      call Broadcast_logical (this%fire_lsm_zcoupling)
      call Broadcast_real (this%fire_lsm_zcoupling_ref)
      call Broadcast_real (this%fire_viscosity_bg)
      call Broadcast_real (this%fire_viscosity_band)
      call Broadcast_integer (this%fire_viscosity_ngp)
      call Broadcast_logical (this%fmoist_run)
      call Broadcast_integer (this%fmoist_freq)
      call Broadcast_real (this%fmoist_dt)
      call Broadcast_real (this%fire_wind_height)
      call Broadcast_logical (this%fire_is_real_perim)
      call Broadcast_real (this%frac_fburnt_to_smoke)
      call Broadcast_real (this%fuelmc_g)
      call Broadcast_real (this%fuelmc_g_live)
      call Broadcast_real (this%fuelmc_c)

      call Broadcast_integer (this%ideal_opt)
      call Broadcast_integer (this%fuel_opt)
      call Broadcast_integer (this%ros_opt)
      call Broadcast_integer (this%emis_opt)
      call Broadcast_integer (this%wind_vinterp_opt)

      call Broadcast_integer (this%fire_num_ignitions)

      call Broadcast_real (this%fire_ignition_start_lon1)
      call Broadcast_real (this%fire_ignition_start_lat1)
      call Broadcast_real (this%fire_ignition_end_lon1)
      call Broadcast_real (this%fire_ignition_end_lat1)
      call Broadcast_real (this%fire_ignition_ros1)
      call Broadcast_real (this%fire_ignition_start_time1)
      call Broadcast_real (this%fire_ignition_end_time1)
      call Broadcast_real (this%fire_ignition_radius1)

      call Broadcast_real (this%fire_ignition_start_lon2)
      call Broadcast_real (this%fire_ignition_start_lat2)
      call Broadcast_real (this%fire_ignition_end_lon2)
      call Broadcast_real (this%fire_ignition_end_lat2)
      call Broadcast_real (this%fire_ignition_ros2)
      call Broadcast_real (this%fire_ignition_start_time2)
      call Broadcast_real (this%fire_ignition_end_time2)
      call Broadcast_real (this%fire_ignition_radius2)

      call Broadcast_real (this%fire_ignition_start_lon3)
      call Broadcast_real (this%fire_ignition_start_lat3)
      call Broadcast_real (this%fire_ignition_end_lon3)
      call Broadcast_real (this%fire_ignition_end_lat3)
      call Broadcast_real (this%fire_ignition_ros3)
      call Broadcast_real (this%fire_ignition_start_time3)
      call Broadcast_real (this%fire_ignition_end_time3)
      call Broadcast_real (this%fire_ignition_radius3)

      call Broadcast_real (this%fire_ignition_start_lon4)
      call Broadcast_real (this%fire_ignition_start_lat4)
      call Broadcast_real (this%fire_ignition_end_lon4)
      call Broadcast_real (this%fire_ignition_end_lat4)
      call Broadcast_real (this%fire_ignition_ros4)
      call Broadcast_real (this%fire_ignition_start_time4)
      call Broadcast_real (this%fire_ignition_end_time4)
      call Broadcast_real (this%fire_ignition_radius4)

      call Broadcast_real (this%fire_ignition_start_lon5)
      call Broadcast_real (this%fire_ignition_start_lat5)
      call Broadcast_real (this%fire_ignition_end_lon5)
      call Broadcast_real (this%fire_ignition_end_lat5)
      call Broadcast_real (this%fire_ignition_ros5)
      call Broadcast_real (this%fire_ignition_start_time5)
      call Broadcast_real (this%fire_ignition_end_time5)
      call Broadcast_real (this%fire_ignition_radius5)

        ! Ideal block
      call Broadcast_real (this%dx)
      call Broadcast_real (this%dy)

      call Broadcast_integer (this%nx)
      call Broadcast_integer (this%ny)

      call Broadcast_real (this%zonal_wind)
      call Broadcast_real (this%meridional_wind)
      call Broadcast_integer (this%fuel_cat)
      call Broadcast_real (this%dz_dx)
      call Broadcast_real (this%dz_dy)
      call Broadcast_real (this%elevation)

      call Broadcast_real (this%cen_lat)
      call Broadcast_real (this%cen_lon)
      call Broadcast_real (this%stand_lon)
      call Broadcast_real (this%true_lat_1)
      call Broadcast_real (this%true_lat_2)

        ! time block
      call Broadcast_integer (this%start_year)
      call Broadcast_integer (this%start_month)
      call Broadcast_integer (this%start_day)
      call Broadcast_integer (this%start_hour)
      call Broadcast_integer (this%start_minute)
      call Broadcast_integer (this%start_second)
      call Broadcast_integer (this%end_year)
      call Broadcast_integer (this%end_month)
      call Broadcast_integer (this%end_day)
      call Broadcast_integer (this%end_hour)
      call Broadcast_integer (this%end_minute)
      call Broadcast_integer (this%end_second)
      call Broadcast_real (this%dt)
      call Broadcast_integer (this%interval_output)

      call Broadcast_integer (this%num_tiles)
      call Broadcast_integer (this%tile_strategy)

        ! Atm block
      call Broadcast_integer (this%interval_atm)
      call Broadcast_integer (this%kde)

    contains

      subroutine Broadcast_integer (val)

        implicit none

        integer, intent(in) :: val

        integer :: ierr


        call Mpi_bcast(val, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)

        if (ierr /= MPI_SUCCESS) &
            call Stop_simulation ('Error broadcasting integer value')

      end subroutine Broadcast_integer

      subroutine Broadcast_logical (val)

        implicit none

        logical, intent(in) :: val

        integer :: ierr


        call Mpi_bcast (val, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)

        if (ierr /= MPI_SUCCESS) &
            call Stop_simulation ('Error broadcasting logical value')

      end subroutine Broadcast_logical

      subroutine Broadcast_real (val)

        implicit none

        real, intent(in) :: val

        integer :: ierr


        call Mpi_bcast (val, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)

        if (ierr /= MPI_SUCCESS) &
            call Stop_simulation ('Error broadcasting real value')

      end subroutine Broadcast_real

#endif

    end subroutine Broadcast_nml

    subroutine Check_nml (this)

      implicit none

      class (namelist_t), intent (in out) :: this

      if (this%ideal_opt /= 0 .and. this%fmoist_run) &
          call Stop_simulation ('ideal runs do not support a FMC model')

    end subroutine Check_nml

    subroutine Init_atm_block_legacy (this, file_name)

      implicit none

      class (namelist_t), intent (in out) :: this
      character (len = *), intent (in) :: file_name

      integer :: kde, interval_atm
      integer :: unit_nml, io_stat
      character (len = :), allocatable :: msg


      namelist /atm/ kde, interval_atm


      interval_atm = 0
        ! The following vars are legacy vars
      kde = 2

      open (newunit = unit_nml, file = trim (file_name), action = 'read', iostat = io_stat)
      if (io_stat /= 0) then
        msg = 'Problems opening namelist file ' // trim (file_name)
        call Stop_simulation (msg)
      end if

      read (unit_nml, nml = atm, iostat = io_stat)
      if (io_stat /= 0) call Stop_simulation ('Problems reading namelist atm block')
      close (unit_nml)

      this%interval_atm = interval_atm

        ! Legacy vars
      this%kde = kde

    end subroutine Init_atm_block_legacy

    subroutine Init_fire_block (this, file_name)

      implicit none

      class (namelist_t), intent (in out) :: this
      character (len = *), intent (in) :: file_name

      integer :: fire_print_msg = 0           ! "write fire statistics, 0 no writes, 1+ for more"  ""
      real :: fire_atm_feedback = 1.0         ! "the heat fluxes to the atmosphere are multiplied by this" "1"
      integer :: fire_upwinding = 9           ! "upwind normal spread: 1=standard, 2=godunov, 3=eno, 4=sethian, 5=2nd-order, 6=WENO3, 7=WENO5, 8=hybrid WENO3/ENO1, 9=hybrid WENO5/ENO1" "1"
      real :: fire_viscosity = 0.4            ! "artificial viscosity in level set method" "1"
      logical :: fire_lsm_reinit = .true.     ! "flag to activate reinitialization of level set method"
      integer :: fire_lsm_reinit_iter = 1     ! "number of iterations for the reinitialization PDE"
      integer :: fire_upwinding_reinit = 4    ! "numerical scheme (space) for reinitialization PDE: 1=WENO3, 2=WENO5, 3=hybrid WENO3-ENO1, 4=hybrid WENO5-ENO1"
      integer :: fire_lsm_band_ngp = 4        ! "number of grid points around lfn=0 that WENO5/3 is used (ENO1 elsewhere), for fire_upwinding_reinit=4,5 and fire_upwinding=8,9 options"
      logical :: fire_lsm_zcoupling = .false. ! "flag to activate reference velocity at a different height from fire_wind_height"
      real :: fire_lsm_zcoupling_ref = 50.0   ! "reference height from wich u at fire_wind_hegiht is calculated using a logarithmic profile" "m"
      real :: fire_viscosity_bg = 0.4         ! "artificial viscosity in the near-front region" "1"
      real :: fire_viscosity_band = 0.5       ! "number of times the hybrid advection band to transition from fire_viscosity_bg to fire_viscosity" "1"
      integer :: fire_viscosity_ngp = 2       ! "number of grid points around lfn=0 where low artificial viscosity is used = fire_viscosity_bg"
      logical :: fmoist_run = .false.         ! "run moisture model (on the atmospheric grid), output to fmc_gc"
      integer :: fmoist_freq = 0              ! "frequency to run moisture model 0: use fmoist_dt, k>0: every k timesteps" "1"
      real :: fmoist_dt = 600                 ! "moisture model time step" "s"
      real :: fire_wind_height = 6.096        ! "height of uah,vah wind in fire spread formula" "m"
      integer :: wind_vinterp_opt = 0         ! "wind (adjustment factor) interpolation option"
      logical :: fire_is_real_perim = .false. ! .false. = point/line ignition, .true. = observed perimeter"
      real :: frac_fburnt_to_smoke = 0.02     ! "parts per unit of burned fuel becoming smoke " "g_smoke/kg_air"
      real :: fuelmc_g = 0.08                 ! Fuel moisture content ground (Dead FMC)
      real :: fuelmc_g_live = 0.30            ! Fuel moisture content ground (Live FMC). 30% Completely cured, treat as dead fuel
      real :: fuelmc_c = 1.00                 ! Fuel moisture content canopy

      integer :: ideal_opt = IDEAL_OPT_DEFAULT

        ! Objects
      integer :: fuel_opt = 1 ! Fuel model
      integer :: ros_opt = 0 ! ROS parameterization
      integer :: fmc_opt = -1 ! FMC model
      integer :: emis_opt = 0 ! Smoke emissions

        ! ignitions
      integer :: fire_num_ignitions = 0

      real :: fire_ignition_start_lon1 = 0.0  ! "long coord of start of ignition line" "deg"
      real :: fire_ignition_start_lat1 = 0.0  ! "lat coord of start of ignition line" "deg"
      real :: fire_ignition_end_lon1 = 0.0    ! "long coord of end of ignition line" "deg"
      real :: fire_ignition_end_lat1 = 0.0    ! "lat coord of end of ignition line" "deg"
      real :: fire_ignition_ros1 = 0.01       ! "rate of spread during ignition" "m/s"
      real :: fire_ignition_start_time1 = 0.0 ! "ignition line start time" "s"
      real :: fire_ignition_end_time1 = 0.0   ! "ignition line end time" "s"
      real :: fire_ignition_radius1 = 0.0     ! "ignite all within the radius" "m"

      real :: fire_ignition_start_lon2 = 0.0, fire_ignition_start_lat2 = 0.0, fire_ignition_end_lon2 = 0.0, &
          fire_ignition_end_lat2 = 0.0, &
          fire_ignition_ros2 = 0.01, fire_ignition_start_time2 = 0.0, fire_ignition_end_time2 = 0.0, fire_ignition_radius2 = 0.0

      real :: fire_ignition_start_lon3 = 0.0, fire_ignition_start_lat3 = 0.0, fire_ignition_end_lon3 = 0.0, &
          fire_ignition_end_lat3 = 0.0, &
          fire_ignition_ros3 = 0.01, fire_ignition_start_time3 = 0.0, fire_ignition_end_time3 = 0.0, fire_ignition_radius3 = 0.0

      real :: fire_ignition_start_lon4 = 0.0, fire_ignition_start_lat4 = 0.0, fire_ignition_end_lon4 = 0.0, &
          fire_ignition_end_lat4 = 0.0, &
          fire_ignition_ros4 = 0.01, fire_ignition_start_time4 = 0.0, fire_ignition_end_time4 = 0.0, fire_ignition_radius4 = 0.0

      real :: fire_ignition_start_lon5 = 0.0, fire_ignition_start_lat5 = 0.0, fire_ignition_end_lon5 = 0.0, &
          fire_ignition_end_lat5 = 0.0, &
          fire_ignition_ros5 = 0.01, fire_ignition_start_time5 = 0.0, fire_ignition_end_time5 = 0.0, fire_ignition_radius5 = 0.0

      namelist /fire/  fire_print_msg, fire_atm_feedback, &
          fire_upwinding, fire_viscosity, fire_lsm_reinit, &
          fire_lsm_reinit_iter, fire_upwinding_reinit, fire_lsm_band_ngp, fire_lsm_zcoupling, fire_lsm_zcoupling_ref, &
          fire_viscosity_bg, fire_viscosity_band, fire_viscosity_ngp, fmoist_run, &
          fmoist_freq, fmoist_dt, &
          fire_wind_height, fire_is_real_perim, frac_fburnt_to_smoke, fuelmc_g, &
          fuelmc_g_live, fuelmc_c, &
          ideal_opt, &
            ! objects
          fuel_opt, ros_opt, fmc_opt, emis_opt, &
          wind_vinterp_opt, &
            ! Ignitions
          fire_num_ignitions, &
            ! Ignition 1
          fire_ignition_start_lon1, fire_ignition_start_lat1, fire_ignition_end_lon1, fire_ignition_end_lat1, &
          fire_ignition_ros1, fire_ignition_start_time1, fire_ignition_end_time1, fire_ignition_radius1, &
            ! Ignition 2
          fire_ignition_start_lon2, fire_ignition_start_lat2, fire_ignition_end_lon2, fire_ignition_end_lat2, &
          fire_ignition_ros2, fire_ignition_start_time2, fire_ignition_end_time2, fire_ignition_radius2, &
            ! Ignition 3
          fire_ignition_start_lon3, fire_ignition_start_lat3, fire_ignition_end_lon3, fire_ignition_end_lat3, &
          fire_ignition_ros3, fire_ignition_start_time3, fire_ignition_end_time3, fire_ignition_radius3, &
            ! Ignition 4
          fire_ignition_start_lon4, fire_ignition_start_lat4, fire_ignition_end_lon4, fire_ignition_end_lat4, &
          fire_ignition_ros4, fire_ignition_start_time4, fire_ignition_end_time4, fire_ignition_radius4, &
            ! Ignition 5
          fire_ignition_start_lon5, fire_ignition_start_lat5, fire_ignition_end_lon5, fire_ignition_end_lat5, &
          fire_ignition_ros5, fire_ignition_start_time5, fire_ignition_end_time5, fire_ignition_radius5

      integer :: unit_nml, io_stat
      character (len = :), allocatable :: msg



      open (newunit = unit_nml, file = trim (file_name), action = 'read', iostat = io_stat)
      if (io_stat /= 0) then
        msg = 'Problems opening namelist file ' // trim (file_name)
        call Stop_simulation (msg)
      end if

      read (unit_nml, nml = fire)
      if (io_stat /= 0) call Stop_simulation ('Problems reading namelist fire block')
      close (unit_nml)

      this%fire_print_msg = fire_print_msg
      this%fire_atm_feedback = fire_atm_feedback
      this%fire_upwinding = fire_upwinding
      this%fire_viscosity = fire_viscosity
      this%fire_lsm_reinit = fire_lsm_reinit
      this%fire_lsm_reinit_iter = fire_lsm_reinit_iter
      this%fire_upwinding_reinit = fire_upwinding_reinit
      this%fire_lsm_band_ngp = fire_lsm_band_ngp
      this%fire_lsm_zcoupling = fire_lsm_zcoupling
      this%fire_lsm_zcoupling_ref = fire_lsm_zcoupling_ref
      this%fire_viscosity_bg = fire_viscosity_bg
      this%fire_viscosity_band = fire_viscosity_band
      this%fire_viscosity_ngp = fire_viscosity_ngp
      this%fmoist_run = fmoist_run
      this%fmoist_freq = fmoist_freq
      this%fmoist_dt = fmoist_dt
      this%fire_wind_height = fire_wind_height
      this%fire_is_real_perim = fire_is_real_perim
      this%frac_fburnt_to_smoke = frac_fburnt_to_smoke
      this%fuelmc_g = fuelmc_g
      this%fuelmc_g_live = fuelmc_g_live
      this%fuelmc_c = fuelmc_c

      this%ideal_opt = ideal_opt

      this%fuel_opt = fuel_opt
      this%ros_opt = ros_opt
      this%fmc_opt = fmc_opt
      this%emis_opt = emis_opt
      this%wind_vinterp_opt = wind_vinterp_opt

      this%fire_num_ignitions = fire_num_ignitions

      this%fire_ignition_start_lon1 = fire_ignition_start_lon1
      this%fire_ignition_start_lat1 = fire_ignition_start_lat1
      this%fire_ignition_end_lon1 = fire_ignition_end_lon1
      this%fire_ignition_end_lat1 = fire_ignition_end_lat1
      this%fire_ignition_ros1 = fire_ignition_ros1
      this%fire_ignition_start_time1 = fire_ignition_start_time1
      this%fire_ignition_end_time1 = fire_ignition_end_time1
      this%fire_ignition_radius1 = fire_ignition_radius1

      this%fire_ignition_start_lon2 = fire_ignition_start_lon2
      this%fire_ignition_start_lat2 = fire_ignition_start_lat2
      this%fire_ignition_end_lon2 = fire_ignition_end_lon2
      this%fire_ignition_end_lat2 = fire_ignition_end_lat2
      this%fire_ignition_ros2 = fire_ignition_ros2
      this%fire_ignition_start_time2 = fire_ignition_start_time2
      this%fire_ignition_end_time2 = fire_ignition_end_time2
      this%fire_ignition_radius2 = fire_ignition_radius2

      this%fire_ignition_start_lon3 = fire_ignition_start_lon3
      this%fire_ignition_start_lat3 = fire_ignition_start_lat3
      this%fire_ignition_end_lon3 = fire_ignition_end_lon3
      this%fire_ignition_end_lat3 = fire_ignition_end_lat3
      this%fire_ignition_ros3 = fire_ignition_ros3
      this%fire_ignition_start_time3 = fire_ignition_start_time3
      this%fire_ignition_end_time3 = fire_ignition_end_time3
      this%fire_ignition_radius3 = fire_ignition_radius3

      this%fire_ignition_start_lon4 = fire_ignition_start_lon4
      this%fire_ignition_start_lat4 = fire_ignition_start_lat4
      this%fire_ignition_end_lon4 = fire_ignition_end_lon4
      this%fire_ignition_end_lat4 = fire_ignition_end_lat4
      this%fire_ignition_ros4 = fire_ignition_ros4
      this%fire_ignition_start_time4 = fire_ignition_start_time4
      this%fire_ignition_end_time4 = fire_ignition_end_time4
      this%fire_ignition_radius4 = fire_ignition_radius4

      this%fire_ignition_start_lon5 = fire_ignition_start_lon5
      this%fire_ignition_start_lat5 = fire_ignition_start_lat5
      this%fire_ignition_end_lon5 = fire_ignition_end_lon5
      this%fire_ignition_end_lat5 = fire_ignition_end_lat5
      this%fire_ignition_ros5 = fire_ignition_ros5
      this%fire_ignition_start_time5 = fire_ignition_start_time5
      this%fire_ignition_end_time5 = fire_ignition_end_time5
      this%fire_ignition_radius5 = fire_ignition_radius5

    end subroutine Init_fire_block

    subroutine Init_ideal_block (this, file_name)

      implicit none

      class (namelist_t), intent (in out) :: this
      character (len = *), intent (in) :: file_name

      real :: dx, dy, zonal_wind, meridional_wind, cen_lat, cen_lon, stand_lon, true_lat_1, true_lat_2, &
          dz_dx, dz_dy, elevation
      integer :: nx, ny, fuel_cat

      character (len = :), allocatable :: msg
      integer :: unit_nml, io_stat

      namelist /ideal/ dx, dy, nx, ny, zonal_wind, meridional_wind, fuel_cat, &
          dz_dx, dz_dy, elevation, cen_lat, cen_lon, stand_lon, true_lat_1, true_lat_2


        ! Set default values
      dx = DX_DEFAULT
      dy = DX_DEFAULT
      nx = NX_DEFAULT
      ny = NX_DEFAULT

      zonal_wind = U_DEFAULT
      meridional_wind = V_DEFAULT
      fuel_cat = FUEL_CAT_DEFAULT
      dz_dx = DZ_DX_DEFAULT
      dz_dy = DZ_DX_DEFAULT
      elevation = ELEVATION_DEFAULT

      cen_lat = LAT_DEFAULT
      cen_lon = LON_DEFAULT
      stand_lon = LON_DEFAULT
      true_lat_1 = LAT_DEFAULT
      true_lat_2 = LAT_DEFAULT

      open (newunit = unit_nml, file = trim (file_name), action = 'read', iostat = io_stat)
      if (io_stat /= 0) then
        msg = 'Problems opening namelist file ' // trim (file_name)
        call Stop_simulation (msg)
      end if

      read (unit_nml, nml = ideal, iostat = io_stat)
      if (io_stat /= 0) call Stop_simulation ('Problems reading namelist ideal block')
      close (unit_nml)

      this%dx = dx
      this%dy = dy

      this%nx = nx
      this%ny = ny

      this%zonal_wind = zonal_wind
      this%meridional_wind = meridional_wind
      this%fuel_cat = fuel_cat
      this%dz_dx = dz_dx
      this%dz_dy = dz_dy
      this%elevation = elevation

      this%cen_lat = cen_lat
      this%cen_lon = cen_lon
      this%stand_lon = stand_lon
      this%true_lat_1 = true_lat_1
      this%true_lat_2 = true_lat_2

    end subroutine Init_ideal_block

    subroutine Init_time_block (this, file_name)

      implicit none

      class (namelist_t), intent (in out) :: this
      character (len = *), intent (in) :: file_name

      integer :: start_year, start_month, start_day, start_hour, start_minute, start_second, &
          end_year, end_month, end_day, end_hour, end_minute, end_second, interval_output, &
          num_tiles, tile_strategy
      real :: dt

      character (len = :), allocatable :: msg
      integer :: unit_nml, io_stat

      namelist /time/ start_year, start_month, start_day, start_hour, start_minute, start_second, &
          end_year, end_month, end_day, end_hour, end_minute, end_second, dt, interval_output, &
          num_tiles


      start_year = 0
      start_month = 0
      start_day = 0
      start_hour = 0
      start_minute = 0
      start_second = 0
      end_year = 0
      end_month = 0
      end_day = 0
      end_hour = 0
      end_minute = 0
      end_second = 0
      dt = 2.0
      interval_output = 0
      num_tiles = 1
      tile_strategy = 0

      open (newunit = unit_nml, file = trim (file_name), action = 'read', iostat = io_stat)
      if (io_stat /= 0) then
        msg = 'Problems opening namelist file ' // trim (file_name)
        call Stop_simulation (msg)
      end if

      read (unit_nml, nml = time, iostat = io_stat)
      if (io_stat /= 0) call Stop_simulation ('Problems reading namelist time block')
      close (unit_nml)

      this%start_year = start_year
      this%start_month = start_month
      this%start_day = start_day
      this%start_hour = start_hour
      this%start_minute = start_minute
      this%start_second = start_second
      this%end_year = end_year
      this%end_month = end_month
      this%end_day = end_day
      this%end_hour = end_hour
      this%end_minute = end_minute
      this%end_second = end_second
      this%dt = dt
      this%interval_output = interval_output

      this%num_tiles = num_tiles
      this%tile_strategy = tile_strategy

    end subroutine Init_time_block

    subroutine Init_namelist (this, file_name)

      implicit none

      class (namelist_t), intent (out) :: this
      character (len = *), intent (in) :: file_name

      logical, parameter :: DEBUG_LOCAL = .false.


      if (DEBUG_LOCAL) call Print_message ('  Entering subroutine Read_namelist')

      call this%Init_time_block (file_name = trim (file_name))
      call this%Init_fire_block (file_name = trim (file_name))
      call this%Init_atm_block (file_name = trim (file_name))
      if (this%ideal_opt > 0) call this%Init_ideal_block (file_name = trim (file_name))

      call this%Check_nml ()

      if (DEBUG_LOCAL) call Print_message ('  Leaving subroutine Read_namelist')

    end subroutine Init_namelist

  end module namelist_mod
