; Created (2022) by YeonJin Jung and Chenhao Qian at Cornell University
; Funding provided by SCRI

; An agent-based model that simulates Listeria spp. behavior in retail stores and evaluate control strategies
; each tick represents an hour

extensions [csv matrix rnd]

;Defining global variables that are used in the model. Note: sliders and choosers on the interface are already global, so they were not defined here
globals [
  operation-schedule
  event day week
  clean-time operation-time
  zone-to-zone avg-listeria-transferred
  introduction-food sum-food-load sum-food-transfer employee-fcs nfcs-fcs
  initial-zone-prevalence traffic-level

  ;Global input parameters
  consumer-prev all-box-prevalence food-conc food-tc maintenance-load rleak-load
  prob-cleanable-cln prob-cleanable-dcln all-cln-reduction all-dcln-reduction
  mu-max-rt mu-max-at af
  K box-prevalence-min box-prevalence-max
  ch-weekend-wet ch-weekday-wet cl-weekend-wet cl-weekday-wet ch-weekend-dry ch-weekday-dry cl-weekend-dry cl-weekday-dry cr-weekend-total cr-weekday-total
  stype-tc-matrix stype-std-matrix expert-link-min-matrix expert-link-ml-matrix expert-link-max-matrix
  p-transfer tc flow-rate box-size
  p11 p12 p13 p14 p21 p22 p23 p24 p31 p32 p33 p34 p41 p42 p43 p44
  tc11 tc12 tc13 tc14 tc15 tc21 tc22 tc24 tc25 tc31 tc34 tc41 tc42 tc43 tc51 tc52
  floor-to-ss-tc floor-to-cb-tc floor-conc floor-prevalence floor-introduction
  consumer-tc consumer-intro-wet consumer-intro-dry consumer-load-wet consumer-load-dry

  ;List of outcomes that gets rest after each simulation
  concentration-list time-contaminated-list max-consec-contam-list time-detect-list max-consec-detect-list

  ;Lists for data collection
  all-count-list
  all-conc-list
  all-time-contaminated-list
  all-max-consec-contam-list
  all-time-detect-list
  all-max-consec-detect-list
  all-contacts-list
  all-transfers-list
  all-prev-list
  all-maintenance-events-list
  all-roof-leak-events-list

  ;;Data collection based on location
  cutting-all-conc-list
  cutting-all-count-list
  cutting-all-prev
  cutting-all-prev-list

  wet-all-conc-list
  wet-all-count-list
  wet-all-prev
  wet-all-prev-list

  dry-all-conc-list
  dry-all-count-list
  dry-all-prev
  dry-all-prev-list

  storage-all-conc-list
  storage-all-count-list
  storage-all-prev
  storage-all-prev-list

  ;;Data collection based on hygienic zones
  z1-all-conc-list
  z1-all-count-list
  z1-all-prev
  z1-all-prev-list

  z2-all-conc-list
  z2-all-count-list
  z2-all-prev
  z2-all-prev-list

  ;;Data collection based on agents used for validation
  cb-count-list
  cb-prev
  cb-prev-list
  ck-count-list
  ck-prev
  ck-prev-list
  cs-count-list
  cs-prev
  cs-prev-list
  sink-count-list
  sink-prev
  sink-prev-list
  hsink-count-list
  hsink-prev
  hsink-prev-list
  employee-count-list
  employee-prev
  employee-prev-list
  runner-count-list
  runner-prev
  runner-prev-list
  wets-count-list
  wets-prev
  wets-prev-list
  wsh-count-list
  wsh-prev
  wsh-prev-list
  drys-count-list
  drys-prev
  drys-prev-list

  collect-time

  ;Variables used for rare introduction events
  maintenance-event maintenance-time roof-leak-event total-sa roof-leak-sa roof-leak-time

  ;Operation schedule
  cutting-operation-schedule
  dry-operation-schedule
  wet-operation-schedule
  runner-operation-schedule

  ;Operation schedule in different locations of the retail store for different days
  cutting-sunday-1 cutting-monday-1 cutting-tuesday-1 cutting-wednesday-1 cutting-thursday-1 cutting-friday-1 cutting-saturday-1
  cutting-sunday-2 cutting-monday-2 cutting-tuesday-2 cutting-wednesday-2 cutting-thursday-2 cutting-friday-2 cutting-saturday-2
  cutting-sunday-3 cutting-monday-3 cutting-tuesday-3 cutting-wednesday-3 cutting-thursday-3 cutting-friday-3 cutting-saturday-3
  cutting-sunday-4 cutting-monday-4 cutting-tuesday-4 cutting-wednesday-4 cutting-thursday-4 cutting-friday-4 cutting-saturday-4
  dry-sunday-1 dry-monday-1 dry-tuesday-1 dry-wednesday-1 dry-thursday-1 dry-friday-1 dry-saturday-1
  dry-sunday-2 dry-monday-2 dry-tuesday-2 dry-wednesday-2 dry-thursday-2 dry-friday-2 dry-saturday-2
  dry-sunday-3 dry-monday-3 dry-tuesday-3 dry-wednesday-3 dry-thursday-3 dry-friday-3 dry-saturday-3
  dry-sunday-4 dry-monday-4 dry-tuesday-4 dry-wednesday-4 dry-thursday-4 dry-friday-4 dry-saturday-4
  wet-sunday-1 wet-monday-1 wet-tuesday-1 wet-wednesday-1 wet-thursday-1 wet-friday-1 wet-saturday-1
  wet-sunday-2 wet-monday-2 wet-tuesday-2 wet-wednesday-2 wet-thursday-2 wet-friday-2 wet-saturday-2
  wet-sunday-3 wet-monday-3 wet-tuesday-3 wet-wednesday-3 wet-thursday-3 wet-friday-3 wet-saturday-3
  wet-sunday-4 wet-monday-4 wet-tuesday-4 wet-wednesday-4 wet-thursday-4 wet-friday-4 wet-saturday-4
  runner-sunday-1 runner-monday-1 runner-tuesday-1 runner-wednesday-1 runner-thursday-1 runner-friday-1 runner-saturday-1
  runner-sunday-2 runner-monday-2 runner-tuesday-2 runner-wednesday-2 runner-thursday-2 runner-friday-2 runner-saturday-2
  runner-sunday-3 runner-monday-3 runner-tuesday-3 runner-wednesday-3 runner-thursday-3 runner-friday-3 runner-saturday-3
  runner-sunday-4 runner-monday-4 runner-tuesday-4 runner-wednesday-4 runner-thursday-4 runner-friday-4 runner-saturday-4

  ;events
  cutting-event dry-event wet-event runner-event

  ]

breed [ zones a-zone] ; node agents classified as zone objects
breed [ listeria a-listeria] ; Listeria Agents

; every link breed was declared as either directed or undirected
directed-link-breed [contact-links contact-link]
undirected-link-breed [proximity-links proximity-link]

zones-own [ ; characteristics of each agent
  z-category ; hygienic zone classification of either 1, 2
  z-item-name ; name of an agent
  z-height ;distance from the floor
  z-area ; surface area of the agent in cm^2
  z-cleanable? ; 0 indicates uncleanable and 1 indicates cleanable, used to describe if agent gets cleaned or not during the cleaning process
  z-location ; different locations in the retail store: cutting station, storage, wet display area, and dry display area
  z-material-category ; zone classification based on the type of material used (stainless steel = 1, plastic = 2, cardboard = 3, hand = 4)
  z-water ; current water level on the agent
  z-default-water ; level of water initial present on the agent [ dry, visible water, moist]
  z-listeria ;number of Listeria present on agent in CFU
  z-listeria-concentration ; concentration of listeria present at that agent/surface are of the agent in CFU/cm^2
  z-prev ; prevalence of Listeria on different agents
  z-time-contaminated ; keeps track of total time the agent is contaminated with Listeria (counts ticks when z-listeria != 0)
  z-max-consec-contam ; keeps track of consecutive time the agent is contaminated with Listeria
  z-time-detect ; keeps track of total time Listeria is detected on an agent
  z-max-consec-detect ; keeps track of consecutive time Listeria is detected
  z-contam-counter ; keeps track of number of times that an agent was contamited
  z-prev-counter ; intermediate counting step used to obtain the maximum consecutive time the Lister is detected on an agent
  z-contacts ;number of times the agent is contacted by other agent  with contamination
  z-transfers ;number of times the agent transfers contamination to adjacent agent
  z-food ; number of times the agent is contaminated from incoming product
  z-maintenance ; number of times the agent is contaminated from maintenance event
  z-roof-leak ; number of times the agent is contaminated from roof leak event
  z-niches-established ; number of times an uncleanable site becomes contaminated
  z-out-links ; counts the number of out-directed links
  z-in-links ; counts the number of in-directed links
  z-undirected-links ; counts the number of undirected links
]

patches-own [
  p-water ; the water level on the patch
  p-listeria ; number of listeria present at patch
  p-listeria-concentration  ; concentration of listeria present at patch/625cm^2
  p-traffic ;assigned traffic level from traffic map
  p-area   ;area of each patch = 25 x 25 = 625 cm^2
]

to setup ; Setting up the initial model environment
  clear-all
  file-close-all
  with-local-randomness[ ;we interrupt the global seed during setup so that we get different combinations of parameter values when sampling the parameter space
;    random-seed new-seed ;this sets a new seed each iteration, even if we set a global seed from the beginning in BSpace - we do not know this seed value
    random-seed local-seed
    import-network
    ask zones [zones-setup]
    setup-environment
    import-matrices
    setup-submodel-params
    ask links [ set color black set thickness 0.2 ]
    create-listeria round ((initial-zone-prevalence / 100) * count zones) [
      listeria-setup
    ]
    setup-weekly-schedule
  ]

  ;Creating empty lists for data collection for the initial setup
  set all-count-list [ ]
  set all-conc-list [ ]
  set all-time-contaminated-list [ ]
  set all-max-consec-contam-list [ ]
  set all-time-detect-list [ ]
  set all-max-consec-detect-list [ ]
  set all-contacts-list [ ]
  set all-transfers-list [ ]
  set all-prev-list [ ]
  set all-maintenance-events-list [ ]
  set all-roof-leak-events-list [ ]

  set cutting-all-conc-list [ ]
  set cutting-all-count-list [ ]
  set cutting-all-prev-list [ ]

  set wet-all-conc-list [ ]
  set wet-all-count-list [ ]
  set wet-all-prev-list [ ]

  set dry-all-conc-list [ ]
  set dry-all-count-list [ ]
  set dry-all-prev-list [ ]

  set storage-all-conc-list [ ]
  set storage-all-count-list [ ]
  set storage-all-prev-list [ ]

  set z1-all-conc-list [ ]
  set z1-all-count-list [ ]
  set z1-all-prev-list [ ]

  set z2-all-conc-list [ ]
  set z2-all-count-list [ ]
  set z2-all-prev-list [ ]

  set cb-count-list [ ]
  set cb-prev-list [ ]
  set ck-count-list [ ]
  set ck-prev-list [ ]
  set cs-count-list [ ]
  set cs-prev-list [ ]
  set sink-count-list [ ]
  set sink-prev-list [ ]
  set hsink-count-list [ ]
  set hsink-prev-list [ ]
  set employee-count-list [ ]
  set employee-prev-list [ ]
  set runner-count-list [ ]
  set runner-prev-list [ ]
  set wets-count-list [ ]
  set wets-prev-list [ ]
  set wsh-count-list [ ]
  set wsh-prev-list [ ]
  set drys-count-list [ ]
  set drys-prev-list [ ]


;  create-output-files
;  write-output 2
  reset-ticks

end

to create-output-files ; these output files are written to collect data when running a single iteration - mainly for testing purposes, they are not utilized in simulation experiments
  if (file-exists? "TimeSeriesZoneConcen.csv" ) [;;will refer to as File 1
    carefully [file-delete "TimeSeriesZoneConcen.csv" ] [ ] ]
  if (file-exists? "TimeSeriesZoneCont.csv" ) [;;will refer to as File 1
    carefully [file-delete "TimeSeriesZoneCont.csv" ] [ ] ]
  if (file-exists? "ZoneData.csv" ) [;;will refer to as File 2
    carefully [file-delete "ZoneData.csv" ] [ ] ]

  let headings-file-1 [ "hours" ] ;making col header of file "TimeSeriesZoneConcen.csv"
  let zone-item [ "," ]
  foreach sort-on [who] zones ; builds the other col headings by using who number
      [ [?1] -> ask ?1 [
        set headings-file-1 lput who headings-file-1
        set zone-item lput z-item-name zone-item
        ]
  ]
    ;;print headings-file-1

  file-open "TimeSeriesZoneConcen.csv"
  let headings1-converted csv:to-row headings-file-1
  let zones-converted csv:to-row zone-item
  file-print  headings1-converted
  file-print zones-converted
  file-close

  set headings-file-1 [ "hours" ] ;making col header of file "TimeSeriesZoneCont.csv"
  set zone-item [ "," ]
  foreach sort-on [who] zones ; builds the other col headings by using who number
      [ [?1] -> ask ?1 [
        set headings-file-1 lput who headings-file-1
        set zone-item lput z-item-name zone-item
        ]
  ]
    ;;print headings-file-1

  file-open "TimeSeriesZoneCont.csv"
  set headings1-converted csv:to-row headings-file-1
  set zones-converted csv:to-row zone-item
  file-print  headings1-converted
  file-print zones-converted
  file-close

  let headings-file-2 [ "who" "zone_item" "x" "y" "zone" "height" "area" "cleanable" "equipment" "part" "out_links" "in_links" "undirected_links" "max-consec-contam" "contacts" "transfers" "food" "zone_4"] ;making col header of file "ZoneData.csv"
  file-open "ZoneData.csv"
  let headings2-converted csv:to-row headings-file-2
  file-print  headings2-converted
  file-close
end

to import-matrices ; importing transfer probability and coefficient matrices
  let expert-min (csv:from-file "expert-transfer-min-matrix_produce.csv")
  set expert-link-min-matrix matrix:from-row-list expert-min

  let expert-ml (csv:from-file "expert-transfer-ml-matrix_produce.csv")
  set expert-link-ml-matrix matrix:from-row-list expert-ml

  let expert-max (csv:from-file "expert-transfer-max-matrix_produce.csv")
  set expert-link-max-matrix matrix:from-row-list expert-max

  let stype-tc (csv:from-file "transfer-tc-matrix-stype.csv")
  set stype-tc-matrix matrix:from-row-list stype-tc

  let stype-std (csv:from-file "transfer-std-matrix-stype.csv")
  set stype-std-matrix matrix:from-row-list stype-std
end

to setup-submodel-params ; defining global parameters for the model - Refer to Table of Parameters
  set af 200 / 67 ; adjustment factor for converting Lm prevalence to Listeria spp.
  set mu-max-rt randomfloat-in-range -0.0092 0.025 ;maximum growth rate at refrigeration temperature (4 +- 2C) Marik et al., 2019.
  set mu-max-at randomfloat-in-range 0.014 0.183; maximum growth rate at ambient temperature (>= 20C) Marik et al., 2019.
  set K (10 ^ 6.85) ;FDA/FSIS. Interagency Risk Assessment: Listeria monocytogenes in Retail Delicatessens; Technical Report. 1–175 (Food and Drug Administration, United States Department of Agriculture, 2013). Available at, https://www.fda.gov/files/food/published/Interagency-Risk-Assessment--Listeria-monocytogenes-in-Retail-Delicatessens-Response-to-Public-Comments-Sept.-2013-%28PDF%29.pdf
  set ch-weekend-wet 252 ; high contact rate/hr on wet shelf during weekend
  set ch-weekday-wet 176 ; high contact rate/hr on wet shelf during weekday
  set cl-weekend-wet 236 ; low contact rate/hr on wet shelf during weekend
  set cl-weekday-wet 120 ; low contact rate/hr on wet shelf during weekday
  set ch-weekend-dry 108 * 12; high contact rate/hr on dry shelf during weekned
  set ch-weekday-dry 55 * 12; high contact rate/hr on dry shelf during weekday
  set cl-weekend-dry 55 * 12; low contact rate/hr on dry shelf during weekned
  set cl-weekday-dry 27 * 12; low contact rate/hr on dry shelf during weekday
  set cr-weekend-total ((ch-weekend-wet + ch-weekend-dry + cl-weekend-wet + cl-weekend-dry) * 2 * 9)
  set cr-weekday-total ((ch-weekday-wet + ch-weekday-dry + cl-weekday-wet + cl-weekday-dry) * 5 * 9)
  set food-conc (random-gamma 0.18 0.425)


  set consumer-tc (10 ^ random-normal (-3.14) (1.19)) ; transfer coefficient from consumer to wet and display shelves (Hand -> Plastic calculated from Hoelzer et al.,  2012)and used for both Hand->Cardboard
  set consumer-prev (random-triangular 0.013 0.059 0.12)

  ;(ifelse
    ;scenario = 9 [
      ;set consumer-prev (random-triangular 0.013 0.059 0.12) * 0.1 ; reduced listeria prevalence on consumer's hand by 90%
    ;]
    ;else
    ;[
      ;set consumer-prev (random-triangular 0.013 0.059 0.12) ; Listeria prevalence on consumer (food handler's hand) from Patpazimos et al., 2022
   ; ]
 ; )

  set all-cln-reduction (10 ^ (random-pert -1.5 -0.5 0 4)) ; cleaning
  set all-dcln-reduction (10 ^ (random-pert -8 -6 -1.5 4)) ; deep cleaning

  set prob-cleanable-cln 90
  set prob-cleanable-dcln 95
  ;(ifelse
    ;scenario = 8 [ ; Scenario 8: increased cleaning efficacy scenario
      ;set prob-cleanable-cln 95
      ;set prob-cleanable-dcln 99
    ;]
    ;else
    ;[
      ;set prob-cleanable-cln 90 ; probability that cleanable agent is cleaned
      ;set prob-cleanable-dcln 95 ; probability that cleanable agent is deep cleaned
    ;]
   ;)

  set box-prevalence-min 0.003 * af ; min prevalence of Listeria in incoming raw materials
  set box-prevalence-max 0.0074 * af ; max prevalence of Listeria in incoming raw materials
  set all-box-prevalence (randomfloat-in-range box-prevalence-min box-prevalence-max)

   ;(ifelse
   ; scenario = 1 [
    ;  set food-conc (random-gamma 0.18 0.425) * 0.5 ; Scenario 1: Reducing Listeria concentration in incoming produce by 50%
    ;]
    ;scenario = 2 [
     ; set food-conc (random-gamma 0.18 0.425) * 0.1 ; Scenario 2: Reducing Listeria concentration in incoming produce by 90%
    ;]

    ;else
    ;[
     ; set food-conc (random-gamma 0.18 0.425) ; Baseline Scenario : samples CFU/g for level of L spp in contaminated incoming product - direct gamma calculation
    ;]
   ;)

  ;(ifelse
    ;scenario = 3 [
      ;set all-box-prevalence (randomfloat-in-range box-prevalence-min box-prevalence-max) * 0.5 ; Scenario 3: Reducing Listeria prevalence in incoming produce by 50%
    ;]
    ;scenario = 4 [
      ;set all-box-prevalence (randomfloat-in-range box-prevalence-min box-prevalence-max) * 0.1 ; Scenario 4: Reducing Listeria prevalence in incoming produce by 90%
    ;]
    ;else
    ;[
      ;set all-box-prevalence randomfloat-in-range box-prevalence-min box-prevalence-max
    ;]
   ;)

  set food-tc (10 ^ random-normal (-1.72) (1.07)) ; transfer coefficient from produce to employee (Hand to Vegetable in Hoelzer 2012) -
  if food-tc > 1 [set food-tc 1]
  set flow-rate 1400 ;1000 boxes ; flow rate/hr of incoming materials - data obtained from the retail store
  set box-size 1200 ; grams of product per box (i.e., 1 flow rate); estimate for a box of lettuce from online database
  set initial-zone-prevalence 0 ;Standard Scenario
  set floor-conc (10 ^ random-normal (4.2) (2.2)) ; Initial Listeria concentration on the floor (Hammons dissertation)
  if  floor-conc < 1 [set floor-conc 1]
  if  floor-conc > 7.4 [set floor-conc 7.4]
  set floor-prevalence 0.079 * af ;probability that the patch is contaminated Sauders et al., 2009 (Martin's cart wheel prevalence data)

  set maintenance-load 108 ; Amount of Listeria introduced during a maintenance event (CFU)
  set maintenance-time (list (random 167) (168 + random 167) (336 + random 167) (504 + random 167)) ; Choose one time of hour in a day each week for maintenance events
  set collect-time (list (random 167) (168 + random 167) (336 + random 95) (504 + random 167)) ; Choose one time of hour in a day each week for data collection
  set rleak-load 293 ; Amount of Listeria introducted during an event of roof leak (CFU)
  set total-sa 10173600 ; Total surface area of the retail store in cm2
  set roof-leak-sa 10133 ; total surface area affected by roof leak cm2
  set roof-leak-time random 671

  reset-lists
  setup-transfer-params
end

to reset-lists
  set concentration-list []
  set time-contaminated-list []
  set max-consec-contam-list []
  set time-detect-list []
  set max-consec-detect-list []
end

to setup-transfer-params ; reading in transfer matrices from .csv files
  set p-transfer [ ]
  set tc [ ]
  let min11  (matrix:get expert-link-min-matrix 0 0) ;expert elicitation probabilities
  let ml11    (matrix:get expert-link-ml-matrix 0 0)
  let max11  (matrix:get expert-link-max-matrix 0 0)
  let min12  (matrix:get expert-link-min-matrix 0 1)
  let ml12   (matrix:get expert-link-ml-matrix 0 1)
  let max12 (matrix:get expert-link-max-matrix 0 1)
  let min13  (matrix:get expert-link-min-matrix 0 2)
  let ml13   (matrix:get expert-link-ml-matrix 0 2)
  let max13 (matrix:get expert-link-max-matrix 0 2)
  let min14  (matrix:get expert-link-min-matrix 0 3)
  let ml14   (matrix:get expert-link-ml-matrix 0 3)
  let max14 (matrix:get expert-link-max-matrix 0 3)

  let min21  (matrix:get expert-link-min-matrix 1 0) ;expert elicitation probabilities
  let ml21    (matrix:get expert-link-ml-matrix 1 0)
  let max21  (matrix:get expert-link-max-matrix 1 0)
  let min22  (matrix:get expert-link-min-matrix 1 1)
  let ml22   (matrix:get expert-link-ml-matrix 1 1)
  let max22 (matrix:get expert-link-max-matrix 1 1)
  let min23  (matrix:get expert-link-min-matrix 1 2)
  let ml23   (matrix:get expert-link-ml-matrix 1 2)
  let max23 (matrix:get expert-link-max-matrix 1 2)
  let min24  (matrix:get expert-link-min-matrix 1 3)
  let ml24   (matrix:get expert-link-ml-matrix 1 3)
  let max24 (matrix:get expert-link-max-matrix 1 3)

  let min31  (matrix:get expert-link-min-matrix 2 0) ;assumed probabilities
  let ml31    (matrix:get expert-link-ml-matrix 2 0)
  let max31  (matrix:get expert-link-max-matrix 2 0)
  let min32  (matrix:get expert-link-min-matrix 2 1)
  let ml32   (matrix:get expert-link-ml-matrix 2 1)
  let max32 (matrix:get expert-link-max-matrix 2 1)
  let min33  (matrix:get expert-link-min-matrix 2 2)
  let ml33   (matrix:get expert-link-ml-matrix 2 2)
  let max33 (matrix:get expert-link-max-matrix 2 2)
  let min34  (matrix:get expert-link-min-matrix 2 3)
  let ml34   (matrix:get expert-link-ml-matrix 2 3)
  let max34 (matrix:get expert-link-max-matrix 2 3)

  let min41  (matrix:get expert-link-min-matrix 3 0) ;expert elicitation probabilities
  let ml41    (matrix:get expert-link-ml-matrix 3 0)
  let max41  (matrix:get expert-link-max-matrix 3 0)
  let min42  (matrix:get expert-link-min-matrix 3 1)
  let ml42   (matrix:get expert-link-ml-matrix 3 1)
  let max42 (matrix:get expert-link-max-matrix 3 1)
  let min43  (matrix:get expert-link-min-matrix 3 2)
  let ml43   (matrix:get expert-link-ml-matrix 3 2)
  let max43 (matrix:get expert-link-max-matrix 3 2)
  let min44  (matrix:get expert-link-min-matrix 3 3)
  let ml44   (matrix:get expert-link-ml-matrix 3 3)
  let max44 (matrix:get expert-link-max-matrix 3 3)

  set p-transfer  lput (list random-pert min11 ml11 max11 4 random-pert min12 ml12 max12 4 random-pert min13 ml13 max13 4 random-pert min14 ml14 max14 4) p-transfer
  set p-transfer  lput (list random-pert min21 ml21 max21 4 random-pert min22 ml22 max22 4 random-pert min23 ml23 max23 4 random-pert min24 ml24 max24 4) p-transfer
  set p-transfer  lput (list random-pert min31 ml31 max31 4 random-pert min32 ml32 max32 4 random-pert min33 ml33 max33 4 random-pert min34 ml34 max34 4) p-transfer
  set p-transfer  lput (list random-pert min41 ml41 max41 4 random-pert min42 ml42 max42 4 random-pert min43 ml43 max43 4 random-pert min44 ml44 max44 4) p-transfer

  set p11 (item 0 (item 0 p-transfer)) set p12 (item 1 (item 0 p-transfer)) set p13 (item 2 (item 0 p-transfer)) set p14 (item 3 (item 0 p-transfer))
  set p21 (item 0 (item 1 p-transfer)) set p22 (item 1 (item 1 p-transfer)) set p23 (item 2 (item 1 p-transfer)) set p24 (item 3 (item 1 p-transfer))
  set p31 (item 0 (item 2 p-transfer)) set p32 (item 1 (item 2 p-transfer)) set p33 (item 2 (item 2 p-transfer)) set p34 (item 3 (item 2 p-transfer))
  set p41 (item 0 (item 3 p-transfer)) set p42 (item 1 (item 3 p-transfer)) set p43 (item 2 (item 3 p-transfer)) set p44 (item 3 (item 3 p-transfer))

  let mu11  (matrix:get stype-tc-matrix 0 0) ; stainless steel to stainless steel
  let std11 (matrix:get stype-std-matrix 0 0)
  let mu12  (matrix:get stype-tc-matrix 0 1) ; stainless steel to plastic
  let std12 (matrix:get stype-std-matrix 0 1)
  let mu13  (matrix:get stype-tc-matrix 0 2) ; stinless steel to cardboard
  let std13 (matrix:get stype-std-matrix 0 2)
  let mu14  (matrix:get stype-tc-matrix 0 3) ; stainless steel to hand
  let std14 (matrix:get stype-std-matrix 0 3)
  let mu15  (matrix:get stype-tc-matrix 0 4) ; stainless steel to glove
  let std15 (matrix:get stype-std-matrix 0 4)

  let mu21  (matrix:get stype-tc-matrix 1 0) ; plastic to stainless steel
  let std21 (matrix:get stype-std-matrix 1 0)
  let mu22  (matrix:get stype-tc-matrix 1 1) ; plastic to plastic
  let std22 (matrix:get stype-std-matrix 1 1)
  let mu24  (matrix:get stype-tc-matrix 1 3) ; plastic to hand
  let std24 (matrix:get stype-std-matrix 1 3)
  let mu25  (matrix:get stype-tc-matrix 1 4) ; plastic to glove
  let std25 (matrix:get stype-std-matrix 1 4)

  let mu31  (matrix:get stype-tc-matrix 2 0) ; cardboard to stainless steel
  let std31 (matrix:get stype-std-matrix 2 0)
  let mu34  (matrix:get stype-tc-matrix 2 3) ; cardboard to hand
  let std34 (matrix:get stype-std-matrix 2 3)

  let mu41  (matrix:get stype-tc-matrix 3 0) ; Hand to stainless steel
  let std41 (matrix:get stype-std-matrix 3 0)
  let mu42  (matrix:get stype-tc-matrix 3 1) ; Hand to plastic
  let std42 (matrix:get stype-std-matrix 3 1)
  let mu43  (matrix:get stype-tc-matrix 3 2) ; Hand to cardboard
  let std43 (matrix:get stype-std-matrix 3 2)

  let mu51  (matrix:get stype-tc-matrix 4 0) ; Glove to stainless steel
  let std51 (matrix:get stype-std-matrix 4 0)
  let mu52  (matrix:get stype-tc-matrix 4 1) ; Glove to plastic
  let std52 (matrix:get stype-std-matrix 4 1)

  set tc lput (list (random-normal mu11 std11) (10 ^ random-normal mu12 std12) (10 ^ random-normal mu13 std13) (10 ^ random-normal mu14 std14) (random-normal mu15 std15) ) tc
  set tc lput (list (10 ^ random-normal mu21 std21) (10 ^ random-normal mu22 std22) 0  (10 ^ random-normal mu24 std24) (random-normal mu25 std25) ) tc
  set tc lput (list (10 ^ random-normal mu31 std31) 0 0  (10 ^ random-normal mu34 std34) 0 ) tc
  set tc lput (list (10 ^ random-normal mu41 std41) (10 ^ random-normal mu42 std42) (10 ^ random-normal mu43 std43) 0 0 ) tc
  set tc lput (list (random-normal mu51 std51) (random-normal mu52 std52) 0 0 0) tc

  set tc11 (item 0 (item 0 tc)) set tc12 (item 1 (item 0 tc)) set tc13 (item 2 (item 0 tc)) set tc14 (item 3 (item 0 tc)) set tc15 (item 4 (item 0 tc))
  set tc21 (item 0 (item 1 tc)) set tc22 (item 1 (item 1 tc))set tc24 (item 3 (item 1 tc)) set tc25 (item 4 (item 1 tc))
  ;(ifelse
    ;scenario = 12 [
      ;set tc31 (item 1 (item 1 tc))
    ;]
    ;[
      ;set tc31 (item 0 (item 2 tc))
    ;]
   ;)
  set tc31 (item 0 (item 2 tc)) set tc34 (item 3 (item 2 tc))
  set tc41 (item 0 (item 3 tc)) set tc42 (item 1 (item 3 tc)) set tc43 (item 2 (item 3 tc))
  set tc51 (item 0 (item 4 tc)) set tc52 (item 1 (item 4 tc))

  let ceramic-to-produce randomfloat-in-range 0.0011 0.1698
  let produce-to-ss randomfloat-in-range 0.0053 0.2373 ;
  set floor-to-ss-tc ceramic-to-produce * produce-to-ss
  let produce-to-cb randomfloat-in-range 0.0056 0.1356; assumed the same as produce to plastic
  set floor-to-cb-tc ceramic-to-produce * produce-to-cb
end

to import-network ; setting up agents with agent attributes and all the links
  set-default-shape turtles "circle"
  import-attributes
  import-directed-links
  import-undirected-links
  reset-ticks
end

to import-attributes ; this creates agents with their individual characteristics from the agent list
  file-close-all
  ;file-open "Agents - Original.txt"
  ;print ("Original List")
  file-open "agents.txt" ; save excel file without headers as .txt - file needs to be in same folder as netlogo file
  ; each row of file is an agent
   ;each column contains agent attributes in this order:
   ;item_name xcor ycor z-category z-height z-area z-cleanable? z-location
let i 1
  while [not file-at-end?]
  [
    let items split file-read-line "\t"
    let itemsA (list
      item 0 items
      read-from-string item 1 items
      read-from-string item 2 items
      read-from-string item 3 items
      read-from-string item 4 items
      read-from-string item 5 items
      read-from-string item 6 items
      item 7 items
      read-from-string item 8 items
      read-from-string item 9 items
    )
    create-zones 1 [
      set z-item-name item 0 itemsA
      set xcor item 1 itemsA
      set ycor item 2 itemsA
      set z-category item 3 itemsA
      set z-height item 4 itemsA
      set z-area item 5 itemsA
      ifelse (item 6 itemsA) = 1 [
        set z-cleanable? true
      ] [
        set z-cleanable? false
      ]
      set z-location item 7 itemsA
      set z-material-category item 8 itemsA
      set z-default-water item 9 itemsA
    ]
  ]
  file-close
end

to import-directed-links ; sets up directed links
  file-close-all
  file-open "dlinks.txt"
    ;(ifelse ; Secnario 11: Limiting Listeria transmission between equipment surfaces by removing (4) links between dry shelf - consumer scale
    ;scenario = 11 [
      ;file-open "dlinks_s11.txt"
    ;]
    ;else
    ;[
      ;file-open "dlinks.txt"
    ;]
  ;)
  while [not file-at-end?] [
    let items read-from-string (word "[" file-read-line "]")
    ask get-node (item 0 items) [
      create-contact-link-to get-node (item 1 items)
    ]  ;directed links
  ]
  file-close
end

to import-undirected-links ; sets up undirected links ;
  file-close-all
  file-open "links.txt"
  while [not file-at-end?] [
    let items read-from-string (word "[" file-read-line "]")
    ask get-node (item 0 items) [
      create-proximity-link-with get-node (item 1 items)
    ] ;undirected links
  ]
  file-close
end

to-report split [ string delim ] ; procedure used to read the file
  report reduce [ [?1 ?2] ->
    ifelse-value (?2 = delim)
      [ lput "" ?1 ]
      [ lput word last ?1 ?2 but-last ?1 ]
  ] fput [""] n-values (length string) [ [?1] -> substring string ?1 (?1 + 1)]
end

to-report get-node [id] ; procedure used to create links between agents
  report one-of turtles with [who = id]
end

to zones-setup ; sets shape and color of agents depending on agent characteristics (e.g., hygienic zones)
  set z-listeria-concentration 0
  set z-listeria 0
  set z-water z-default-water
  set z-prev 0
  if z-category = 1 [
    set shape "circle" set size 1 set color (16 - z-water)
  ]
  if z-category = 2 [
    set shape "triangle" set size 1 set color (26 - z-water)
  ]
  if z-item-name = "employee" [
    set shape "person" set size 3 set color black set hidden? true
  ]
  if z-item-name = "runner"[
    set shape "car" set size 3 set color gray set hidden? true
  ]
  set z-out-links count my-out-contact-links
  set z-in-links count my-in-contact-links
  set z-undirected-links count my-proximity-links
end

to setup-environment ; set inital conditions and characteristics of patches
  update-water ( "low" ) ;The cutting station is not "In-Use" at the first hour of simulation
  update-traffic ( "no" )
  run environment-view
end

to update-water [level] ; reads in different water maps
  if level = "high" [
    ;print("water-high")
    file-open "water-high.txt"
    while [not file-at-end?] [
      foreach sort patches [ [?1] ->
        ask ?1 [
          set p-water file-read]
      ]
    ]
    file-close
]

  if level = "low" [
    ;print("water-low")
    file-open "water-low.txt"
    while [not file-at-end?] [
      foreach sort patches [ [?1] ->
        ask ?1 [
          set p-water file-read]
      ]
    ]
    file-close
  ]

  if level = "dry-clean" [
    ;print("dry-clean")
    file-open "water-dry-clean.txt"
    while [not file-at-end?] [
      foreach sort patches [ [?1] ->
        ask ?1 [
          set p-water file-read]
      ]
    ]
    file-close
  ]

 if level = "no" [
  ;print("water-none")
  file-open "water-none.txt"
    ;   read in the floor plan
    while [not file-at-end?] [
      foreach sort patches [ [?1] ->
        ask ?1 [
          set p-water file-read]
      ]
    ]
    file-close
  ]
  water
end

;;environment-view switch requires the two following functions:
to water
  ask patches[ p-water-recolor]
end

to traffic
  ask patches [p-traffic-recolor]
end

to update-traffic [level] ; reads in different traffic maps
  if level = "high" [
    file-open "traffic-high.txt"
    while [not file-at-end?] [
    foreach sort patches [ [?1] ->
  ask ?1 [
   set p-traffic file-read]
  ]]
  file-close
  ]

  if level = "low" [
    file-open "traffic-low.txt"
    while [not file-at-end?] [
    foreach sort patches [ [?1] ->
  ask ?1 [
   set p-traffic file-read]
  ]]
  file-close
  ]

  if level = "no" [
    file-open "traffic-none.txt"
    while [not file-at-end?] [
    foreach sort patches [ [?1] ->
  ask ?1 [
   set p-traffic file-read]
  ]]
  file-close
  ]
end

to setup-weekly-schedule ; ;;reads in operation schedule ;
  file-close-all
  file-open "cutting-station-monthly-cleaning-schedule.csv"
  ;load first week schedule
  set cutting-sunday-1 csv:from-row file-read-line
  set cutting-monday-1 csv:from-row file-read-line
  set cutting-tuesday-1 csv:from-row file-read-line
  set cutting-wednesday-1 csv:from-row file-read-line
  set cutting-thursday-1 csv:from-row file-read-line
  set cutting-friday-1 csv:from-row file-read-line
  set cutting-saturday-1 csv:from-row file-read-line
  ;load second week schedule
  set cutting-sunday-2 csv:from-row file-read-line
  set cutting-monday-2 csv:from-row file-read-line
  set cutting-tuesday-2 csv:from-row file-read-line
  set cutting-wednesday-2 csv:from-row file-read-line
  set cutting-thursday-2 csv:from-row file-read-line
  set cutting-friday-2 csv:from-row file-read-line
  set cutting-saturday-2 csv:from-row file-read-line
  ;load third week schedule
  set cutting-sunday-3 csv:from-row file-read-line
  set cutting-monday-3 csv:from-row file-read-line
  set cutting-tuesday-3 csv:from-row file-read-line
  set cutting-wednesday-3 csv:from-row file-read-line
  set cutting-thursday-3 csv:from-row file-read-line
  set cutting-friday-3 csv:from-row file-read-line
  set cutting-saturday-3 csv:from-row file-read-line
  ;load fourth week schedule
  set cutting-sunday-4 csv:from-row file-read-line
  set cutting-monday-4 csv:from-row file-read-line
  set cutting-tuesday-4 csv:from-row file-read-line
  set cutting-wednesday-4 csv:from-row file-read-line
  set cutting-thursday-4 csv:from-row file-read-line
  set cutting-friday-4 csv:from-row file-read-line
  set cutting-saturday-4 csv:from-row file-read-line
  file-close

  file-open "dry-shelves-monthly-cleaning-schedule.csv"
  ;load first week schedule with DC on wednesday night
  set dry-sunday-1 csv:from-row file-read-line
  set dry-monday-1 csv:from-row file-read-line
  set dry-tuesday-1 csv:from-row file-read-line
  set dry-wednesday-1 csv:from-row file-read-line
  set dry-thursday-1 csv:from-row file-read-line
  set dry-friday-1 csv:from-row file-read-line
  set dry-saturday-1 csv:from-row file-read-line
  ;load second week schedule with DC on wednesday night
  set dry-sunday-2 csv:from-row file-read-line
  set dry-monday-2 csv:from-row file-read-line
  set dry-tuesday-2 csv:from-row file-read-line
  set dry-wednesday-2 csv:from-row file-read-line
  set dry-thursday-2 csv:from-row file-read-line
  set dry-friday-2 csv:from-row file-read-line
  set dry-saturday-2 csv:from-row file-read-line
  ;load third week schedule with DC on wednesday night
  set dry-sunday-3 csv:from-row file-read-line
  set dry-monday-3 csv:from-row file-read-line
  set dry-tuesday-3 csv:from-row file-read-line
  set dry-wednesday-3 csv:from-row file-read-line
  set dry-thursday-3 csv:from-row file-read-line
  set dry-friday-3 csv:from-row file-read-line
  set dry-saturday-3 csv:from-row file-read-line
  ;load fourth week schedule with DC on wednesday night
  set dry-sunday-4 csv:from-row file-read-line
  set dry-monday-4 csv:from-row file-read-line
  set dry-tuesday-4 csv:from-row file-read-line
  set dry-wednesday-4 csv:from-row file-read-line
  set dry-thursday-4 csv:from-row file-read-line
  set dry-friday-4 csv:from-row file-read-line
  set dry-saturday-4 csv:from-row file-read-line
  file-close

  ;(ifelse
    ;scenario = 5 [
      ;file-open "dry-shelves-monthly-cleaning-schedule-s5.csv"
      ;;load first week schedule with DC on wednesday night
      ;set dry-sunday-1 csv:from-row file-read-line
      ;set dry-monday-1 csv:from-row file-read-line
      ;set dry-tuesday-1 csv:from-row file-read-line
      ;set dry-wednesday-1 csv:from-row file-read-line
      ;set dry-thursday-1 csv:from-row file-read-line
      ;set dry-friday-1 csv:from-row file-read-line
      ;set dry-saturday-1 csv:from-row file-read-line
      ;;load second week schedule with DC on wednesday night
      ;set dry-sunday-2 csv:from-row file-read-line
      ;set dry-monday-2 csv:from-row file-read-line
      ;set dry-tuesday-2 csv:from-row file-read-line
      ;set dry-wednesday-2 csv:from-row file-read-line
      ;set dry-thursday-2 csv:from-row file-read-line
      ;set dry-friday-2 csv:from-row file-read-line
      ;set dry-saturday-2 csv:from-row file-read-line
      ;;load third week schedule with DC on wednesday night
      ;set dry-sunday-3 csv:from-row file-read-line
      ;set dry-monday-3 csv:from-row file-read-line
      ;set dry-tuesday-3 csv:from-row file-read-line
      ;set dry-wednesday-3 csv:from-row file-read-line
      ;set dry-thursday-3 csv:from-row file-read-line
      ;set dry-friday-3 csv:from-row file-read-line
      ;set dry-saturday-3 csv:from-row file-read-line
      ;;load fourth week schedule with DC on wednesday night
      ;set dry-sunday-4 csv:from-row file-read-line
      ;set dry-monday-4 csv:from-row file-read-line
      ;set dry-tuesday-4 csv:from-row file-read-line
      ;set dry-wednesday-4 csv:from-row file-read-line
      ;set dry-thursday-4 csv:from-row file-read-line
      ;set dry-friday-4 csv:from-row file-read-line
      ;set dry-saturday-4 csv:from-row file-read-line
      ;file-close
    ;]
    ;;else
    ;[
      ;file-open "dry-shelves-monthly-cleaning-schedule.csv"
      ;;load first week schedule
      ;set dry-sunday-1 csv:from-row file-read-line
      ;set dry-monday-1 csv:from-row file-read-line
      ;set dry-tuesday-1 csv:from-row file-read-line
      ;set dry-wednesday-1 csv:from-row file-read-line
      ;set dry-thursday-1 csv:from-row file-read-line
      ;set dry-friday-1 csv:from-row file-read-line
      ;set dry-saturday-1 csv:from-row file-read-line
      ;;load second week schedule
      ;set dry-sunday-2 csv:from-row file-read-line
      ;set dry-monday-2 csv:from-row file-read-line
      ;set dry-tuesday-2 csv:from-row file-read-line
      ;set dry-wednesday-2 csv:from-row file-read-line
      ;set dry-thursday-2 csv:from-row file-read-line
      ;set dry-friday-2 csv:from-row file-read-line
      ;set dry-saturday-2 csv:from-row file-read-line
      ;;load third week schedule
      ;set dry-sunday-3 csv:from-row file-read-line
      ;set dry-monday-3 csv:from-row file-read-line
      ;set dry-tuesday-3 csv:from-row file-read-line
      ;set dry-wednesday-3 csv:from-row file-read-line
      ;set dry-thursday-3 csv:from-row file-read-line
      ;set dry-friday-3 csv:from-row file-read-line
      ;set dry-saturday-3 csv:from-row file-read-line
      ;;load fourth week schedule
      ;set dry-sunday-4 csv:from-row file-read-line
      ;set dry-monday-4 csv:from-row file-read-line
      ;set dry-tuesday-4 csv:from-row file-read-line
      ;set dry-wednesday-4 csv:from-row file-read-line
      ;set dry-thursday-4 csv:from-row file-read-line
      ;set dry-friday-4 csv:from-row file-read-line
      ;set dry-saturday-4 csv:from-row file-read-line
      ;file-close
    ;]
   ;)

  file-open "wet-shelves-monthly-cleaning-schedule.csv"
  ;load first week schedule weekly deep cleaning
  set wet-sunday-1 csv:from-row file-read-line
  set wet-monday-1 csv:from-row file-read-line
  set wet-tuesday-1 csv:from-row file-read-line
  set wet-wednesday-1 csv:from-row file-read-line
  set wet-thursday-1 csv:from-row file-read-line
  set wet-friday-1 csv:from-row file-read-line
  set wet-saturday-1 csv:from-row file-read-line
  ;load second week schedule weekly deep cleaning
  set wet-sunday-2 csv:from-row file-read-line
  set wet-monday-2 csv:from-row file-read-line
  set wet-tuesday-2 csv:from-row file-read-line
  set wet-wednesday-2 csv:from-row file-read-line
  set wet-thursday-2 csv:from-row file-read-line
  set wet-friday-2 csv:from-row file-read-line
  set wet-saturday-2 csv:from-row file-read-line
  ;load third week schedule weekly deep cleaning
  set wet-sunday-3 csv:from-row file-read-line
  set wet-monday-3 csv:from-row file-read-line
  set wet-tuesday-3 csv:from-row file-read-line
  set wet-wednesday-3 csv:from-row file-read-line
  set wet-thursday-3 csv:from-row file-read-line
  set wet-friday-3 csv:from-row file-read-line
  set wet-saturday-3 csv:from-row file-read-line
  ;load fourth week schedule weekly deep cleaning
  set wet-sunday-4 csv:from-row file-read-line
  set wet-monday-4 csv:from-row file-read-line
  set wet-tuesday-4 csv:from-row file-read-line
  set wet-wednesday-4 csv:from-row file-read-line
  set wet-thursday-4 csv:from-row file-read-line
  set wet-friday-4 csv:from-row file-read-line
  set wet-saturday-4 csv:from-row file-read-line

  ;(ifelse
    ;scenario = 6 [
      ;file-open "wet-shelves-monthly-cleaning-schedule-s6.csv"
      ;;load first week schedule weekly deep cleaning
      ;set wet-sunday-1 csv:from-row file-read-line
      ;set wet-monday-1 csv:from-row file-read-line
      ;set wet-tuesday-1 csv:from-row file-read-line
      ;set wet-wednesday-1 csv:from-row file-read-line
      ;set wet-thursday-1 csv:from-row file-read-line
      ;set wet-friday-1 csv:from-row file-read-line
      ;set wet-saturday-1 csv:from-row file-read-line
      ;;load second week schedule weekly deep cleaning
      ;set wet-sunday-2 csv:from-row file-read-line
      ;set wet-monday-2 csv:from-row file-read-line
      ;set wet-tuesday-2 csv:from-row file-read-line
      ;set wet-wednesday-2 csv:from-row file-read-line
      ;set wet-thursday-2 csv:from-row file-read-line
      ;set wet-friday-2 csv:from-row file-read-line
      ;set wet-saturday-2 csv:from-row file-read-line
      ;;load third week schedule weekly deep cleaning
      ;set wet-sunday-3 csv:from-row file-read-line
      ;set wet-monday-3 csv:from-row file-read-line
      ;set wet-tuesday-3 csv:from-row file-read-line
      ;set wet-wednesday-3 csv:from-row file-read-line
      ;set wet-thursday-3 csv:from-row file-read-line
      ;set wet-friday-3 csv:from-row file-read-line
      ;set wet-saturday-3 csv:from-row file-read-line
      ;;load fourth week schedule weekly deep cleaning
      ;set wet-sunday-4 csv:from-row file-read-line
      ;set wet-monday-4 csv:from-row file-read-line
      ;set wet-tuesday-4 csv:from-row file-read-line
      ;set wet-wednesday-4 csv:from-row file-read-line
      ;set wet-thursday-4 csv:from-row file-read-line
      ;set wet-friday-4 csv:from-row file-read-line
      ;set wet-saturday-4 csv:from-row file-read-line
      ;file-close
    ;]
   ;scenario = 7 [
    ;  file-open "wet-shelves-monthly-cleaning-schedule-s7.csv"
    ;  ;load first week schedule cleaning everyday
    ;  set wet-sunday-1 csv:from-row file-read-line
    ;  set wet-monday-1 csv:from-row file-read-line
    ;  set wet-tuesday-1 csv:from-row file-read-line
    ; set wet-wednesday-1 csv:from-row file-read-line
    ;  set wet-thursday-1 csv:from-row file-read-line
    ;  set wet-friday-1 csv:from-row file-read-line
    ;  set wet-saturday-1 csv:from-row file-read-line
    ;  ;load second week schedule cleaning everyday
    ;  set wet-sunday-2 csv:from-row file-read-line
    ;  set wet-monday-2 csv:from-row file-read-line
    ;  set wet-tuesday-2 csv:from-row file-read-line
    ;  set wet-wednesday-2 csv:from-row file-read-line
    ;  set wet-thursday-2 csv:from-row file-read-line
    ;  set wet-friday-2 csv:from-row file-read-line
    ;  set wet-saturday-2 csv:from-row file-read-line
    ;  ;load third week schedule cleaning everyday
    ;  set wet-sunday-3 csv:from-row file-read-line
    ;  set wet-monday-3 csv:from-row file-read-line
    ;  set wet-tuesday-3 csv:from-row file-read-line
    ;  set wet-wednesday-3 csv:from-row file-read-line
    ;  set wet-thursday-3 csv:from-row file-read-line
    ;  set wet-friday-3 csv:from-row file-read-line
    ;  set wet-saturday-3 csv:from-row file-read-line
    ;  ;load fourth week schedule cleaning everyday
    ;  set wet-sunday-4 csv:from-row file-read-line
    ;  set wet-monday-4 csv:from-row file-read-line
    ;  set wet-tuesday-4 csv:from-row file-read-line
    ;  set wet-wednesday-4 csv:from-row file-read-line
    ;  set wet-thursday-4 csv:from-row file-read-line
    ;  set wet-friday-4 csv:from-row file-read-line
    ;  set wet-saturday-4 csv:from-row file-read-line
    ;]
    ;;else
    ;[
    ;  file-open "wet-shelves-monthly-cleaning-schedule.csv"
    ;  ;load first week schedule
    ;  set wet-sunday-1 csv:from-row file-read-line
    ;  set wet-monday-1 csv:from-row file-read-line
    ;  set wet-tuesday-1 csv:from-row file-read-line
    ;  set wet-wednesday-1 csv:from-row file-read-line
    ;  set wet-thursday-1 csv:from-row file-read-line
    ;  set wet-friday-1 csv:from-row file-read-line
    ;  set wet-saturday-1 csv:from-row file-read-line
    ;  ;load second week schedule
    ;  set wet-sunday-2 csv:from-row file-read-line
    ;  set wet-monday-2 csv:from-row file-read-line
    ;  set wet-tuesday-2 csv:from-row file-read-line
    ;  set wet-wednesday-2 csv:from-row file-read-line
    ;  set wet-thursday-2 csv:from-row file-read-line
    ;  set wet-friday-2 csv:from-row file-read-line
    ;  set wet-saturday-2 csv:from-row file-read-line
    ;  ;load third week schedule
    ;  set wet-sunday-3 csv:from-row file-read-line
    ;  set wet-monday-3 csv:from-row file-read-line
    ;  set wet-tuesday-3 csv:from-row file-read-line
    ;  set wet-wednesday-3 csv:from-row file-read-line
    ;  set wet-thursday-3 csv:from-row file-read-line
    ;  set wet-friday-3 csv:from-row file-read-line
    ;  set wet-saturday-3 csv:from-row file-read-line
    ;  ;load fourth week schedule
    ;  set wet-sunday-4 csv:from-row file-read-line
    ;  set wet-monday-4 csv:from-row file-read-line
    ;  set wet-tuesday-4 csv:from-row file-read-line
    ;  set wet-wednesday-4 csv:from-row file-read-line
    ;  set wet-thursday-4 csv:from-row file-read-line
    ;  set wet-friday-4 csv:from-row file-read-line
    ;  set wet-saturday-4 csv:from-row file-read-line
    ;  file-close
    ;]
   ;)

  file-open "runners-monthly-cleaning-schedule.csv"
  ;load first week schedule
  set runner-sunday-1 csv:from-row file-read-line
  set runner-monday-1 csv:from-row file-read-line
  set runner-tuesday-1 csv:from-row file-read-line
  set runner-wednesday-1 csv:from-row file-read-line
  set runner-thursday-1 csv:from-row file-read-line
  set runner-friday-1 csv:from-row file-read-line
  set runner-saturday-1 csv:from-row file-read-line
  ;load second week schedule
  set runner-sunday-2 csv:from-row file-read-line
  set runner-monday-2 csv:from-row file-read-line
  set runner-tuesday-2 csv:from-row file-read-line
  set runner-wednesday-2 csv:from-row file-read-line
  set runner-thursday-2 csv:from-row file-read-line
  set runner-friday-2 csv:from-row file-read-line
  set runner-saturday-2 csv:from-row file-read-line
  ;load third week schedule
  set runner-sunday-3 csv:from-row file-read-line
  set runner-monday-3 csv:from-row file-read-line
  set runner-tuesday-3 csv:from-row file-read-line
  set runner-wednesday-3 csv:from-row file-read-line
  set runner-thursday-3 csv:from-row file-read-line
  set runner-friday-3 csv:from-row file-read-line
  set runner-saturday-3 csv:from-row file-read-line
  ;load fourth week schedule
  set runner-sunday-4 csv:from-row file-read-line
  set runner-monday-4 csv:from-row file-read-line
  set runner-tuesday-4 csv:from-row file-read-line
  set runner-wednesday-4 csv:from-row file-read-line
  set runner-thursday-4 csv:from-row file-read-line
  set runner-friday-4 csv:from-row file-read-line
  set runner-saturday-4 csv:from-row file-read-line
  file-close
end

to listeria-setup
  set color yellow
  set shape "bug"
  set size 1
end


;this function is executed when "go" is clicked
to go
  if not any? turtles [ stop ]
  if ticks mod 168 = 0 [ output-print "Sunday"] ; output changing every 168 ticks
  if ticks mod 168 = 24 [ output-print "Monday"]
  if ticks mod 168 = 48 [ output-print "Tuesday"]
  if ticks mod 168 = 72 [ output-print "Wednesday"]
  if ticks mod 168 = 96 [ output-print "Thursday"]
  if ticks mod 168 = 120 [ output-print "Friday"]
  if ticks mod 168 = 144 [ output-print "Saturday"]

  increment-contam-time
  increment-detectable-time

  ;Change day every 24 hours
  if ticks mod 24 = 0 [
    set day (day + 1)
    set-operation-schedule
  ]

  ;Change week
  if ticks mod 168 = 0 [
    set week (week + 1)
    reset-week
    if week = 5 [
      stop
    ]
  ]

  set-hourly-event
  run-event
  update-listeria
  grow
  dry-water

  run environment-view

  ; Randomly choose 4 time points in a month for data collection
  if (member? ticks collect-time)
  [
    ask zones with [z-area <= 100] [ifelse z-listeria-concentration > 0.1 [set z-prev 1 ][set z-prev 0]]
    ask zones with [z-area > 100] [ifelse z-listeria-concentration > 0.016 [set z-prev 1][set z-prev 0]]
    monitor-all
    monitor-turtles
  ]

  ;collect contaminated and detected times at the end of the simulation
  if (ticks = 670) [
    monitor-time
  ]
  tick
end

to increment-contam-time
  if (debug-messages) [
    ;print("start: increment-contam-time")
  ]
  ask zones with [z-listeria = 0 and z-contam-counter != 0] [
    set z-contam-counter 0
  ]
  ask zones with [z-listeria > 0] [
    set z-time-contaminated z-time-contaminated + 1
    set z-contam-counter z-contam-counter + 1
    set z-max-consec-contam max( list z-contam-counter z-max-consec-contam)
  ]

  if (debug-messages) [
    ;print("end: increment-contam-time")
  ]
end

to increment-detectable-time
  ask zones with [z-listeria-concentration > 0.1 and z-area <= 100] [
    set z-time-detect z-time-detect + 1
    set z-prev-counter z-prev-counter + 1
    set z-max-consec-detect max(list z-prev-counter z-max-consec-detect)
  ]
  ask zones with [z-listeria-concentration > 0.016 and z-area > 100] [
    set z-time-detect z-time-detect + 1
    set z-prev-counter z-prev-counter + 1
    set z-max-consec-detect max(list z-prev-counter z-max-consec-detect)
  ]
  ask zones with [z-listeria-concentration <= 0.1 and z-area <= 100] [
    set z-prev-counter 0
  ]
  ask zones with [z-listeria-concentration <= 0.016  and z-area > 100] [
    set z-prev-counter 0
  ]
end

to set-operation-schedule
  if (debug-messages) [
    ;print("start: set-operation-schedule")
  ]
  reset-day
  ;if (debug-messages) [
  ;  ;print("end: set-operation-schedule")
  ;]

  ; week 1
   if (week = 0 and day = 1)[
    set cutting-operation-schedule cutting-sunday-1
    set dry-operation-schedule dry-sunday-1
    set wet-operation-schedule wet-sunday-1
    set runner-operation-schedule runner-sunday-1]
  if (week = 0 and day = 2)[
    set cutting-operation-schedule cutting-monday-1
    set dry-operation-schedule dry-monday-1
    set wet-operation-schedule wet-monday-1
    set runner-operation-schedule runner-monday-1]
  if (week = 0 and day = 3)[
    set cutting-operation-schedule cutting-tuesday-1
    set dry-operation-schedule dry-tuesday-1
    set wet-operation-schedule wet-tuesday-1
    set runner-operation-schedule runner-tuesday-1]
  if (week = 0 and day = 4)[
    set cutting-operation-schedule cutting-wednesday-1
    set dry-operation-schedule dry-wednesday-1
    set wet-operation-schedule wet-wednesday-1
    set runner-operation-schedule runner-wednesday-1]
  if (week = 0 and day = 5)[
    set cutting-operation-schedule cutting-thursday-1
    set dry-operation-schedule dry-thursday-1
    set wet-operation-schedule wet-thursday-1
    set runner-operation-schedule runner-thursday-1]
  if (week = 0 and day = 6)[
    set cutting-operation-schedule cutting-friday-1
    set dry-operation-schedule dry-friday-1
    set wet-operation-schedule wet-friday-1
    set runner-operation-schedule runner-friday-1]
   if (week = 0 and day = 7)[
    set cutting-operation-schedule cutting-saturday-1
    set dry-operation-schedule dry-saturday-1
    set wet-operation-schedule wet-saturday-1
    set runner-operation-schedule runner-saturday-1]


  ;Week 2
  if (week = 1 and day = 1)[
    set cutting-operation-schedule cutting-sunday-2
    set dry-operation-schedule dry-sunday-2
    set wet-operation-schedule wet-sunday-2
    set runner-operation-schedule runner-sunday-2]
  if (week = 1 and day = 2)[
    set cutting-operation-schedule cutting-monday-2
    set dry-operation-schedule dry-monday-2
    set wet-operation-schedule wet-monday-2
    set runner-operation-schedule runner-monday-2]
  if (week = 1 and day = 3)[
    set cutting-operation-schedule cutting-tuesday-2
    set dry-operation-schedule dry-tuesday-2
    set wet-operation-schedule wet-tuesday-2
    set runner-operation-schedule runner-tuesday-2]
  if (week = 1 and day = 4)[
    set cutting-operation-schedule cutting-wednesday-2
    set dry-operation-schedule dry-wednesday-2
    set wet-operation-schedule wet-wednesday-2
    set runner-operation-schedule runner-wednesday-2]
  if (week = 1 and day = 5)[
    set cutting-operation-schedule cutting-thursday-2
    set dry-operation-schedule dry-thursday-2
    set wet-operation-schedule wet-thursday-2
    set runner-operation-schedule runner-thursday-2]
  if (week = 1 and day = 6)[
    set cutting-operation-schedule cutting-friday-2
    set dry-operation-schedule dry-friday-2
    set wet-operation-schedule wet-friday-2
    set runner-operation-schedule runner-friday-2]
   if (week = 1 and day = 7)[
    set cutting-operation-schedule cutting-saturday-2
    set dry-operation-schedule dry-saturday-2
    set wet-operation-schedule wet-saturday-2
    set runner-operation-schedule runner-saturday-2]

  ;Week 3
  if (week = 2 and day = 1)[
    set cutting-operation-schedule cutting-sunday-3
    set dry-operation-schedule dry-sunday-3
    set wet-operation-schedule wet-sunday-3
    set runner-operation-schedule runner-sunday-3]
  if (week = 2 and day = 2)[
    set cutting-operation-schedule cutting-monday-3
    set dry-operation-schedule dry-monday-3
    set wet-operation-schedule wet-monday-3
    set runner-operation-schedule runner-monday-3]
  if (week = 2 and day = 3)[
    set cutting-operation-schedule cutting-tuesday-3
    set dry-operation-schedule dry-tuesday-3
    set wet-operation-schedule wet-tuesday-3
    set runner-operation-schedule runner-tuesday-3]
  if (week = 2 and day = 4)[
    set cutting-operation-schedule cutting-wednesday-3
    set dry-operation-schedule dry-wednesday-3
    set wet-operation-schedule wet-wednesday-3
    set runner-operation-schedule runner-wednesday-3]
  if (week = 2 and day = 5)[
    set cutting-operation-schedule cutting-thursday-3
    set dry-operation-schedule dry-thursday-3
    set wet-operation-schedule wet-thursday-3
    set runner-operation-schedule runner-thursday-3]
  if (week = 2 and day = 6)[
    set cutting-operation-schedule cutting-friday-3
    set dry-operation-schedule dry-friday-3
    set wet-operation-schedule wet-friday-3
    set runner-operation-schedule runner-friday-3]
   if (week = 2 and day = 7)[
    set cutting-operation-schedule cutting-saturday-3
    set dry-operation-schedule dry-saturday-3
    set wet-operation-schedule wet-saturday-3
    set runner-operation-schedule runner-saturday-3]

  ;Week 4
  if (week = 3 and day = 1)[
    set cutting-operation-schedule cutting-sunday-4
    set dry-operation-schedule dry-sunday-4
    set wet-operation-schedule wet-sunday-4
    set runner-operation-schedule runner-sunday-4]
  if (week = 3 and day = 2)[
    set cutting-operation-schedule cutting-monday-4
    set dry-operation-schedule dry-monday-4
    set wet-operation-schedule wet-monday-4
    set runner-operation-schedule runner-monday-4]
  if (week = 3 and day = 3)[
    set cutting-operation-schedule cutting-tuesday-4
    set dry-operation-schedule dry-tuesday-4
    set wet-operation-schedule wet-tuesday-4
    set runner-operation-schedule runner-tuesday-4]
  if (week = 3 and day = 4)[
    set cutting-operation-schedule cutting-wednesday-4
    set dry-operation-schedule dry-wednesday-4
    set wet-operation-schedule wet-wednesday-4
    set runner-operation-schedule runner-wednesday-4]
  if (week = 3 and day = 5)[
    set cutting-operation-schedule cutting-thursday-4
    set dry-operation-schedule dry-thursday-4
    set wet-operation-schedule wet-thursday-4
    set runner-operation-schedule runner-thursday-4]
  if (week = 3 and day = 6)[
    set cutting-operation-schedule cutting-friday-4
    set dry-operation-schedule dry-friday-4
    set wet-operation-schedule wet-friday-4
    set runner-operation-schedule runner-friday-4]
   if (week = 3 and day = 7)[
    set cutting-operation-schedule cutting-saturday-4
    set dry-operation-schedule dry-saturday-4
    set wet-operation-schedule wet-saturday-4
    set runner-operation-schedule runner-saturday-4]

end

to reset-day
  set operation-time 0
  set clean-time 0
end

to reset-week
  set day 1
end

to monitor-turtles
  ;collect prevalence data from specific agents for validation

  ;data collected for cutting board
  set cb-prev (count zones with [z-item-name = "cutting-board" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "cutting-board" and z-listeria-concentration > 0.016 and z-area > 100 ]) * 100
  set cb-prev-list lput cb-prev cb-prev-list

  ;data collected for cutting knife
  set ck-prev (count zones with [z-item-name = "cutting-knife" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "cutting-knife" and z-listeria-concentration > 0.016 and z-area > 100 ]) * 100
  set ck-prev-list lput ck-prev ck-prev-list

  ;data collected for consumer scale
  set cs-prev (count zones with [z-item-name = "consumer-scale" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "consumer-scale" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-item-name = "consumer-scale"]) * 100
  set cs-prev-list lput cs-prev cs-prev-list

  ;data collected for sink
  set sink-prev (count zones with [z-item-name = "sink" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "sink" and z-listeria-concentration > 0.016 and z-area > 100 ]) * 100
  set sink-prev-list lput sink-prev sink-prev-list

  ;data collected for handwash station
  set hsink-prev (count zones with [z-item-name = "handwash-station" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "handwash-station" and z-listeria-concentration > 0.016 and z-area > 100 ]) * 100
  set hsink-prev-list lput hsink-prev hsink-prev-list

  ;data collected for employee's hand
  set employee-prev (count zones with [z-item-name = "employee" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "employee" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-item-name = "employee"]) * 100
  set employee-prev-list lput employee-prev employee-prev-list

  ;data collected for runner
  set runner-prev (count zones with [z-item-name = "runner" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "runner" and z-listeria-concentration > 0.016 and z-area > 100 ]) * 100
  set runner-prev-list lput runner-prev runner-prev-list

  ;data collected for wet shelf
  set wets-prev (count zones with [z-item-name = "wet-shelf" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "wet-shelf" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-item-name = "wet-shelf"]) * 100
  set wets-prev-list lput wets-prev wets-prev-list

  ;data collected for water sprinkler heads
  set wsh-prev (count zones with [z-item-name = "water-sprinkler-head" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "water-sprinkler-head" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-item-name = "water-sprinkler-head"]) * 100
  set wsh-prev-list lput wsh-prev wsh-prev-list

  ;data collected for dry shelves
  set drys-prev (count zones with [z-item-name = "dry-shelf" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-item-name = "dry-shelf" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-item-name = "dry-shelf"]) * 100
  set drys-prev-list lput drys-prev drys-prev-list
end

to monitor-time ;
  ; collect aggregated data for cluster analysis and sensitivity analysis
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-time-contaminated-list lput z-time-contaminated all-time-contaminated-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-max-consec-contam-list lput z-max-consec-contam all-max-consec-contam-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-time-detect-list lput z-time-detect all-time-detect-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-max-consec-detect-list lput z-max-consec-detect all-max-consec-detect-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-contacts-list lput z-contacts all-contacts-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-transfers-list lput z-transfers all-transfers-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-maintenance-events-list lput z-maintenance all-maintenance-events-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-roof-leak-events-list lput z-roof-leak all-roof-leak-events-list]]
end


to monitor-all ;
  ; collect prevlance and concentration for all agents and locations at different sampling times
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-count-list lput z-listeria all-count-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-prev-list lput z-prev all-prev-list]]
  foreach sort-on [ who ] zones [[?1] -> ask ?1 [set all-conc-list lput z-listeria-concentration all-conc-list]]

  ; cutting-station
  ask zones with [z-location = "cutting-station"] [
    set cutting-all-conc-list lput z-listeria-concentration cutting-all-conc-list
    set cutting-all-count-list lput z-listeria cutting-all-count-list
  ]
  set cutting-all-prev (count zones with [z-location = "cutting-station" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = "cutting-station" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [ z-location = "cutting-station"])  * 100
  set cutting-all-prev-list lput cutting-all-prev cutting-all-prev-list

  ; wet-display-area
  ask zones with [z-location = "wet-display-area"] [
    set wet-all-conc-list lput z-listeria-concentration wet-all-conc-list
    set wet-all-count-list lput z-listeria wet-all-count-list
  ]
  set wet-all-prev (count zones with [z-location = "wet-display-area" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = "wet-display-area" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-location = "wet-display-area"])  * 100
  set wet-all-prev-list lput wet-all-prev wet-all-prev-list

   ; dry-display-area
  ask zones with [z-location = "dry-display-area"] [
    set dry-all-conc-list lput z-listeria-concentration dry-all-conc-list
    set dry-all-count-list lput z-listeria dry-all-count-list
  ]
  set dry-all-prev (count zones with [z-location = "dry-display-area" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = "dry-display-area" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [ z-location = "dry-display-area"])  * 100
  set dry-all-prev-list lput dry-all-prev dry-all-prev-list

   ; storage
  ask zones with [z-location = "storage"] [
    set storage-all-conc-list lput z-listeria-concentration storage-all-conc-list
    set storage-all-count-list lput z-listeria storage-all-count-list
  ]
  set storage-all-prev (count zones with [z-location = "storage" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = "storage" and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-location = "storage"])  * 100
  set storage-all-prev-list lput storage-all-prev storage-all-prev-list

  ; z1
  ask zones with [z-category = 1] [
    set z1-all-conc-list lput z-listeria-concentration z1-all-conc-list
    set z1-all-count-list lput z-listeria z1-all-count-list
  ]
  set z1-all-prev (count zones with [z-category = 1 and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-category = 1 and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-category = 1])  * 100
  set z1-all-prev-list lput z1-all-prev z1-all-prev-list

  ; z2
  ask zones with [z-category = 2] [
    set z2-all-conc-list lput z-listeria-concentration z2-all-conc-list
    set z2-all-count-list lput z-listeria z2-all-count-list
  ]
  set z2-all-prev (count zones with [z-category = 2 and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-category = 2 and z-listeria-concentration > 0.016 and z-area > 100 ]) / (count zones with [z-category = 2])  * 100
  set z2-all-prev-list lput z2-all-prev z2-all-prev-list
end


to set-hourly-event
  let hour ticks mod 24
  ;setting hourly event for all four locations
  set cutting-event item hour cutting-operation-schedule
  set dry-event item hour dry-operation-schedule
  set wet-event item hour wet-operation-schedule
  set runner-event item hour runner-operation-schedule
end

to run-event ; here is where you need to bring everything together based on operation schedule these events need to be terms used in the operation schedule .csv file
  let employees (zones with [ z-item-name = "employee" ])
  let runner (zones with [ z-item-name = "runner"])
  let wet-zones (zones with [ z-location =  "wet-display-area"])
  let dry-zones (zones with [ z-location = "dry-display-area"])
  let cutting-zones (zones with [z-location = "cutting-station"])

  ; Traffic levels based on operation times
  if operation-time >= 0 and operation-time < 6 [
    set traffic-level "no"
      update-traffic ("no")
  ]
  if operation-time >= 6 and operation-time < 10 [
    set traffic-level "low"
      update-traffic ("low")
  ]
  if operation-time >= 10 and operation-time < 15 [
    set traffic-level "high"
    update-traffic ("high")
  ]
  if operation-time >= 15 and operation-time < 17 [
    set traffic-level "low"
    update-traffic ("low")
  ]
  if operation-time >= 17 and operation-time < 21 [
    set traffic-level "high"
    update-traffic ("high")
  ]
  if operation-time >= 21 [
    set traffic-level "low"
    update-traffic ("low")
  ]
  ;print(word "operation hour:" operation-time)
  set operation-time (operation-time + 1)

  ;;Scenario 13: Holiday Scenario - store closed after 4 PM on Thanksgiving day
  ;if (week = 3 and day = 5 and operation-time > 16) [
    ;set traffic-level "no"
    ;update-traffic ("no")
    ;set cutting-event "EM"
    ;set wet-event "EM"
    ;set dry-event "EM"
    ;set runner-event "EM"
    ;]

  ;;Scenario 13: Holidary Scenario - high consumer contact rate at all day before Thanksgiving
  ;if (week = 3 and (day = 3 or day = 4) and operation-time >= 6) [
    ;set traffic-level "high"
   ;]

  ;Listeria introduction
  if operation-time >= 6 [
    consumer-introduction
    food-introduction
  ]

  ;Maintenance introduction
  if (member? ticks maintenance-time) [
    maintenance-introduction
  ]

  ;Roof leak introduction
  if (ticks = roof-leak-time) [
    ;print(word "roof-leak-time: " roof-leak-time)
    roof-leak-introduction
  ]

  ;when store is closed
  if runner-event = "EM" [
    ask employees [
      set hidden? true
      ask my-proximity-links [set hidden? true]
      ask listeria-here [ die ] ; assume that listeria are removed from employees when they are not in the room
      set z-listeria 0
      set z-listeria-concentration 0
    ]
    ask runner [
      set hidden? false
      ask my-proximity-links [set hidden? true]
    ]
  ]

  if wet-event = "IU" and cutting-event = "EM" [
    update-water ("low")
  ]

  if dry-event = "DC" [
    update-water ("dry-clean")
  ]

  if runner-event = "IU" [
    ask employees [
      set hidden? false
      ask my-proximity-links [set hidden? false]
    ]
    ask runner [
      set hidden? false
      ask my-proximity-links [set hidden? false]
    ]
    storage-zone-spread
  ]

  if cutting-event = "IU" [
    update-water ("high")
    cutting-zone-spread
    ask cutting-zones [
      set z-water z-default-water
    ]
  ]

  if (wet-event = "IU" or dry-event = "IU") [
    wet-dry-zone-spread
    floor-to-shelf-introduction
  ]

  ;Scenario 10: Improved cleaning on wet display consumer scale
  ;(if (scenario = 10) [
   ; if (operation-time = 0 and wet-event = "EM") [
     ; clean-cs-wet
    ;]
   ;]
  ;)

  ;Scenario 10: Improved cleaning on dry display consumer scale
  ;(if (scenario = 10) [
   ; if (operation-time = 0 and dry-event = "EM") [
     ; clean-cs-dry
    ;]
   ;]
  ;)

  ; Implementing cleaning events for each location
  if (wet-event = "CL" or wet-event = "DC") [
    ask zones with [(z-location = "wet-display-area") and z-cleanable?][
      set z-water 4
    ]
    clean-wet
    set clean-time (clean-time + 1)
  ]

  if (runner-event = "CL") [
      clean-runner
    ask zones with [(z-item-name = "runner") and z-cleanable?][
      set z-water 4
    ]
    set clean-time (clean-time + 1)
  ]

  if (cutting-event = "CL") [
      clean-cutting
    ask zones with [(z-location = "cutting-station") and z-cleanable?][
      set z-water 4
    ]
      set clean-time (clean-time + 1)
  ]

  if (dry-event = "DC") [
      clean-dry
    ask zones with [(z-location = "dry-display-area") and z-cleanable?][
      set z-water 4
    ]
      set clean-time (clean-time + 1)
  ]

  if (cutting-event = "EM") [
    ask zones with [z-location = "cutting-station" and z-default-water = 2][
      set z-water 1
    ]
  ]

  ;print(word "operation hour:" operation-time)
  set operation-time (operation-time + 1)

end

to write-output [file-number]

  if file-number = 1 [
  ;OUTPUT FILE #1 DATA
  let zone-data [  ] ; defines an empty list each tick (as a local var.) that holds concentration for each zone
  set zone-data fput ticks zone-data
  foreach sort-on [ who ] zones
   [ [?1] -> ask ?1
     [ set zone-data lput z-listeria-concentration zone-data ] ]
  file-open  "TimeSeriesZoneConcen.csv"
  let data-to-csv csv:to-row zone-data
  file-print data-to-csv
  file-close

  let cont-data [  ] ; defines an empty list each tick (as a local var.) that holds concentration for each zone
  set cont-data fput ticks cont-data
  foreach sort-on [ who ] zones
   [ [?1] -> ask ?1
     [ set cont-data lput z-time-contaminated cont-data ] ]
  file-open  "TimeSeriesZoneCont.csv"
  set data-to-csv csv:to-row cont-data
  file-print data-to-csv
  file-close
  ]

  if file-number = 2 [
  foreach sort-on [ who ] zones
   [ [?1] -> ask ?1
   [;let zone-data []
    file-open "ZoneData.csv"
    file-type (word who "," z-item-name "," xcor "," ycor "," z-category "," z-height "," z-area "," z-cleanable? "," z-location "," z-out-links "," z-in-links "," z-undirected-links "," z-max-consec-contam "," z-contacts "," z-transfers "," (z-food / ticks) ",")
    file-close]]]
end

; only growth when water is present (2 or 3) and same growth rate
to grow
  ask zones with [(z-water = 2 or z-water = 3)] [
    let N (z-listeria-concentration)
    ifelse z-location = "wet-display-area" or z-location = "storage" [
      set z-listeria-concentration ( ( K * N * e ^ mu-max-rt)/ (K + N * ((e ^ mu-max-rt) - 1 )))
      if z-listeria-concentration > K [
        set z-listeria-concentration K
      ]
      set z-listeria round (z-listeria-concentration * [z-area] of self)
    ]
    [
      set z-listeria-concentration ( ( K * N * e ^ mu-max-at)/ (K + N * ((e ^ mu-max-at) - 1 )))
      if z-listeria-concentration > K [
        set z-listeria-concentration K
      ]
      set z-listeria round (z-listeria-concentration * [z-area] of self)
    ]
  ]
end

to update-listeria
  ask zones with [z-listeria-concentration > K] [
    set z-listeria-concentration K
  ]

  ask zones with [(z-listeria < 1)] [
    let z count listeria-here
  ]
 ask zones with [(z-listeria >= 1)] [
    let z count listeria-here
    if z > 1 [
      ask listeria-here [die]
      hatch-listeria 1 [listeria-setup setxy xcor ycor]
    ]
  ]
end

to dry-water
  ask zones with [(z-water = 4)] [
    set z-water z-default-water
  ]
end

to wet-dry-zone-spread ;zone spread for wet and dry display
  ask zones with [(z-location = "wet-display-area" or z-location = "dry-display-area") and z-listeria > 0] [
    let N1 z-listeria
    let me [who] of self
    let zone-num ([z-category] of self) - 1
    let surface-num ([z-material-category] of self) - 1
    let neighbor-zones (turtle-set (out-link-neighbors) )
    if [z-item-name] of self = "employee" and [z-location] of self = "wet-display-area"[
      set neighbor-zones n-of 5 neighbor-zones
    ]
    if (neighbor-zones != nobody) [
      ask neighbor-zones [
        let zone-num2 ([z-category] of self) - 1
        let surface-num2 ([z-material-category] of self) - 1

        let prob-12  (item zone-num2 (item zone-num p-transfer))
        let prob-21  (item zone-num (item zone-num2 p-transfer))
        if not out-link-neighbor? a-zone me [set prob-21 0]

        let trans-12  (item surface-num2 (item surface-num tc)) ;we keep track of this during variability simulations
        let trans-21  (item surface-num (item surface-num2 tc))
        let N2 z-listeria
        let z count (listeria-here)
        let T12 0
        let T21 0

        ifelse random-float 100 < prob-12 [
          set T12 trans-12 ;(10 ^ random-normal (tc12) (std12)) ;
          ask myself [set z-transfers z-transfers + 1]
          ask self [set z-contacts z-contacts + 1]
            ifelse ((surface-num = 3 or surface-num = 4) and zone-num2 = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num = 1  and zone-num2 = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
            ] [
              set zone-to-zone (zone-to-zone + 1) ; total number of transfers between agents excpet for NFCS-FCS and employee-FCS
            ]
          ]
        ] [
          set T12 0 ; transfer does not occur when the transfer probability is not large enough
        ]
        ifelse random-float 100 < prob-21 [
          if [z-listeria] of self > 0 [
          set T21 trans-21 ;(10 ^ random-normal (tc21) (std21)) ;
            ask self [set z-transfers z-transfers + 1]
            ask myself [set z-contacts z-contacts + 1]
          ifelse ((surface-num2 = 3) and zone-num = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num2 = 1 and zone-num = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
        ] [
              set zone-to-zone (zone-to-zone + 1)
            ]
          ]
        ]
      ] [
          set T21 0
        ]

        let x11 (random-binomial (N1) (1 - T12)) ; Amount of remaining listeria on the agent
        let x21 (random-binomial (N2) (T21)) ; Amount of listeria gettting transferred from neighbor to itself
        if zone-to-zone != 0 [set avg-listeria-transferred (avg-listeria-transferred + (N1 - x11 + x21) / (zone-to-zone + employee-FCS + NFCS-FCS))]
        set z-listeria (N1 + N2 - (x11 + x21)) ; total listeria on neighbor
        set z-listeria-concentration (z-listeria / [z-area] of self)
        if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
        set z-listeria round (z-listeria-concentration * [z-area] of self)

        set N1 (x11 + x21); total listeria on itself

        if (([z-listeria] of self) > 0) and (z = 0) [
          hatch-listeria 1 [listeria-setup setxy xcor ycor]
           if ([not z-cleanable?] of self) [
            set z-niches-established z-niches-established + 1
          ]
        ]
      ]
    ]
    set z-listeria N1
    set z-listeria-concentration (z-listeria / [z-area] of self)
    if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
    set z-listeria round (z-listeria-concentration * [z-area] of self)
  ]
end

to cutting-zone-spread ;zone spread for cutting station
  ask zones with [z-location = "cutting-station" and z-listeria > 0] [
    let N1 z-listeria
    let me [who] of self
    let zone-num ([z-category] of self) - 1
    let surface-num ([z-material-category] of self) - 1
    let neighbor-zones (turtle-set (out-link-neighbors) )
        ;print(word "surface-num:" surface-num)
    ;print(word "name:" [z-item-name] of self)

    if (neighbor-zones != nobody) [
      ask neighbor-zones [
        let zone-num2 ([z-category] of self) - 1
        let surface-num2 ([z-material-category] of self) - 1
                ;print(word "surface-num2:" surface-num2)
        ;print(word "name2:" [z-item-name] of self)

        let prob-12  (item zone-num2 (item zone-num p-transfer))
        let prob-21  (item zone-num (item zone-num2 p-transfer))
        if not out-link-neighbor? a-zone me [set prob-21 0]

        let trans-12  (item surface-num2 (item surface-num tc)) ;we keep track of this during variability simulations
        let trans-21  (item surface-num (item surface-num2 tc))
        let N2 z-listeria
        let z count (listeria-here)
        let T12 0
        let T21 0

        ifelse random-float 100 < prob-12 [
          set T12 trans-12 ;(10 ^ random-normal (tc12) (std12)) ;
          ask myself [set z-transfers z-transfers + 1]
          ask self [set z-contacts z-contacts + 1]
            ifelse ((surface-num = 4) and zone-num2 = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num = 1  and zone-num2 = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
            ] [
              set zone-to-zone (zone-to-zone + 1)
            ]
          ]
        ] [
          set T12 0
        ]
        ifelse random-float 100 < prob-21 [
          if [z-listeria] of self > 0 [
          set T21 trans-21 ;(10 ^ random-normal (tc21) (std21)) ;
            ask self [set z-transfers z-transfers + 1]
            ask myself [set z-contacts z-contacts + 1]
          ifelse ((surface-num2 = 3 or surface-num2 = 4) and zone-num = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num2 = 1 and zone-num = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
        ] [
              set zone-to-zone (zone-to-zone + 1)
            ]
          ]
        ]
        ] [
          set T21 0
        ]
        ;print (word "T12:" T12)
        ;print (word "trans12:" trans-12)
        ;print (word "T21:" T21)
        ;print (word "trans21:" trans-21)
        ;print (word "N1:" N1)
        ;print (word "N2:" N2)
        let x11 (random-binomial (N1) (1 - T12))
        let x21 (random-binomial (N2) (T21))
        if zone-to-zone != 0 [set avg-listeria-transferred (avg-listeria-transferred + (N1 - x11 + x21) / (zone-to-zone + employee-FCS + NFCS-FCS))]
        set z-listeria (N1 + N2 - (x11 + x21))
        ;print(word "N2 new listeria:" z-listeria)
        set z-listeria-concentration (z-listeria / [z-area] of self)
        if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
        set z-listeria round (z-listeria-concentration * [z-area] of self)

        set N1 (x11 + x21)

        if (([z-listeria] of self) > 0) and (z = 0) [
          hatch-listeria 1 [listeria-setup setxy xcor ycor]
           if ([not z-cleanable?] of self) [
            set z-niches-established z-niches-established + 1
          ]
        ]
      ]
    ]
    set z-listeria N1
    set z-listeria-concentration (z-listeria / [z-area] of self)
    if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
    set z-listeria round (z-listeria-concentration * [z-area] of self)
  ]
end

to storage-zone-spread ;zone-spread in storage
  ask zones with [z-location = "storage" and z-listeria > 0] [
    let N1 z-listeria
    let me [who] of self
    let zone-num ([z-category] of self) - 1
    let surface-num ([z-material-category] of self) - 1
    let neighbor-zones (turtle-set (out-link-neighbors) )
        ;print(word "surface-num:" surface-num)
   ;print(word "name:" [z-item-name] of self)

    if (neighbor-zones != nobody) [
      ask neighbor-zones [
        let zone-num2 ([z-category] of self) - 1
        let surface-num2 ([z-material-category] of self) - 1
                ;print(word "surface-num2:" surface-num2)
        ;print(word "name2:" [z-item-name] of self)

        let prob-12  (item zone-num2 (item zone-num p-transfer))
        let prob-21  (item zone-num (item zone-num2 p-transfer))
        if not out-link-neighbor? a-zone me [set prob-21 0]

        let trans-12  (item surface-num2 (item surface-num tc)) ;we keep track of this during variability simulations
        let trans-21  (item surface-num (item surface-num2 tc))
        let N2 z-listeria
        let z count (listeria-here)
        let T12 0
        let T21 0

        ifelse random-float 100 < prob-12 [
          set T12 trans-12 ;(10 ^ random-normal (tc12) (std12)) ;
          ask myself [set z-transfers z-transfers + 1]
          ask self [set z-contacts z-contacts + 1]
            ifelse ((surface-num = 3) and zone-num2 = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num = 1  and zone-num2 = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
            ] [
              set zone-to-zone (zone-to-zone + 1)
            ]
          ]
        ] [
          set T12 0
        ]
        ifelse random-float 100 < prob-21 [
          if [z-listeria] of self > 0 [
          set T21 trans-21 ;(10 ^ random-normal (tc21) (std21)) ;
            ask self [set z-transfers z-transfers + 1]
            ask myself [set z-contacts z-contacts + 1]
          ifelse ((surface-num2 = 3 or surface-num2 = 4) and zone-num = 0) [
            set employee-FCS (employee-FCS + 1)] [
            ifelse (zone-num2 = 1 and zone-num = 0) [
              set NFCS-FCS (NFCS-FCS + 1)
        ] [
              set zone-to-zone (zone-to-zone + 1)
            ]
          ]
        ]
        ][
          set T21 0
        ]
        if ((surface-num2 = 4 and surface-num = 1) and T12 > 0 )[
          print (word "tc14:" T12)
          print (word "avg-listeria-transferred:" avg-listeria-transferred)
        ]
        ;print (word "T12:" T12)
        ;print (word "trans12:" trans-12)
        ;print (word "T21:" T21)
        ;print (word "trans21:" trans-21)
        ;print (word "N1:" N1)
        ;print (word "N2:" N2)
        let x11 (random-binomial (N1) (1 - T12))
        let x21 (random-binomial (N2) (T21))
        if zone-to-zone != 0 [set avg-listeria-transferred (avg-listeria-transferred + (N1 - x11 + x21) / (zone-to-zone + employee-FCS + NFCS-FCS))]
        set z-listeria (N1 + N2 - (x11 + x21))
        ;print(word "N2 new listeria:" z-listeria)
        set z-listeria-concentration (z-listeria / [z-area] of self)
        if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
        set z-listeria round (z-listeria-concentration * [z-area] of self)

        set N1 (x11 + x21)

        if (([z-listeria] of self) > 0) and (z = 0) [
          hatch-listeria 1 [listeria-setup setxy xcor ycor]
           if ([not z-cleanable?] of self) [
            set z-niches-established z-niches-established + 1
          ]
        ]
      ]
    ]
    set z-listeria N1
    set z-listeria-concentration (z-listeria / [z-area] of self)
    if z-listeria-concentration > K [
          set z-listeria-concentration K
        ]
    set z-listeria round (z-listeria-concentration * [z-area] of self)
  ]
end

to food-introduction
  let conc food-conc
  let prevalence all-box-prevalence
  let crh-day-total 0
  let crl-day-total 0
  let daily-box 0
  ifelse day = 1 or day = 7 [
    set daily-box round(flow-rate * 7 * cr-weekend-total / 2 / (cr-weekday-total + cr-weekend-total))
    set crh-day-total  (ch-weekend-wet + ch-weekend-dry)
    set crl-day-total  (cl-weekend-wet + cl-weekend-dry)
    ;print(word "weekend:" daily-box)
  ][
    set daily-box round(flow-rate * 7 * cr-weekday-total / 5 / (cr-weekday-total + cr-weekend-total))
    set crh-day-total  (ch-weekday-wet + ch-weekday-dry)
    set crl-day-total  (cl-weekday-wet + cl-weekday-dry)
    ;print(word "weekday:" daily-box)
  ]
  let hourly-flow-rate 0
  if traffic-level = "high" [set hourly-flow-rate (daily-box / 9 * ( crh-day-total  / ( crh-day-total  + crl-day-total  )))]
  if traffic-level = "low" [set hourly-flow-rate (daily-box / 9 * ( crl-day-total  / ( crh-day-total  + crl-day-total  )))]
  if traffic-level = "no" [set hourly-flow-rate 0]
  ;print(word "hourly-rate:" hourly-flow-rate)
  let contam-box (random-binomial (round(hourly-flow-rate)) (prevalence))
  ;print(word "prevalence:" prevalence)
  ;print(word "#contaminated box:" contam-box)
  repeat contam-box [
    ask one-of zones with [z-item-name = "employee"] [
      let x count listeria-here
      let prob-11 (item 0 (item 0 p-transfer)) ; probability of listeria transfer (zone 1 to zone 1)
      if random-float 100 < prob-11 [
        let load (conc * box-size) ;total listeria concentration on produce
        let y (random-binomial (load) (food-tc))
        set introduction-food (introduction-food + 1)
        set sum-food-load (sum-food-load + load)
        set sum-food-transfer (sum-food-transfer + y)
        ask self [
          set z-listeria (z-listeria + y)
          set z-listeria-concentration (z-listeria / [z-area] of self)
          set z-food z-food + 1
           ;print(word "listeria transferred from box:" y)
         ]
       ]
      if (([z-listeria] of self) > 0) and (x = 0) [
        hatch-listeria 1 [ listeria-setup setxy xcor ycor]
        if ([not z-cleanable?] of self) [set z-niches-established z-niches-established + 1]
      ]

    ]
  ]

end

to consumer-introduction
  let contact-rate-wet 0
  let contact-rate-dry 0
  if traffic-level = "high" [
    ifelse day = 1 or day = 7[
      set contact-rate-wet ch-weekend-wet
      set contact-rate-dry ch-weekend-dry
    ][
      set contact-rate-wet ch-weekday-wet
      set contact-rate-dry ch-weekday-dry
    ]
    ;; Scenario 13 Holiday
    ;if (week = 3 and (day = 3 or day = 4) and operation-time < 22) [
     ;set contact-rate-wet ch-weekend-wet
     ;set contact-rate-dry ch-weekend-dry
   ;]
  ]

  if traffic-level = "low" [
    ifelse day = 1 or day = 7 [
      set contact-rate-wet cl-weekend-wet
      set contact-rate-dry cl-weekend-dry
    ][
      set contact-rate-wet cl-weekday-wet
      set contact-rate-dry cl-weekday-dry
    ]
  ]
  ;print(word "wet contact rate:" contact-rate-wet)
  ;print(word "dry contact rate:" contact-rate-dry)
  let expected-cross-con-wet (random-binomial (contact-rate-wet) (consumer-prev)) ; expected number of listeria cross contamination events from consumer to all wet shelf agents
  let cross-con-wet (random-binomial (expected-cross-con-wet) (p11)) ; actual number of listeria cross contamination events from consumer to all wet shelf agents
  ;print( word "cross-con-wet:" cross-con-wet)
  let expected-cross-con-dry (random-binomial (contact-rate-dry) (consumer-prev)) ;
  let cross-con-dry (random-binomial (expected-cross-con-dry) (p11))
  ;print( word "cross-con-dry:" cross-con-dry)
  let consumer-count random-in-range 1 20 ; Listeria count on consumer (CFU)
  let consumer-transfer round(consumer-tc * consumer-count)
  repeat cross-con-wet [ ; loops over the number of cross contamination events among wet shelf agents
    if random-float 100 <= 50 [
      ask one-of zones with [z-item-name = "wet-shelf"][ ; selects one wet shelf agent each time
        set consumer-intro-wet (consumer-intro-wet + 1)
        set consumer-load-wet consumer-transfer * consumer-intro-wet
        set z-listeria (z-listeria + consumer-transfer)
        set z-listeria-concentration (z-listeria / [z-area] of self)
      ]
    ]
  ]
  repeat cross-con-dry[
    if random-float 100 <= 50 [
      ask one-of zones with [z-item-name = "dry-shelf"][
        set consumer-intro-dry (consumer-intro-dry + 1)
        set consumer-load-dry consumer-transfer * consumer-intro-wet
        set z-listeria (z-listeria + consumer-transfer)
        set z-listeria-concentration (z-listeria / [z-area] of self)
      ]
    ]
  ]
end

to floor-to-shelf-introduction
  let y random 100 ;recontam-rate: 1 per 4 hours from observation at a retail store
  if y < 25 [
    let x random 100
    if x < floor-prevalence * 100 [
        ask one-of zones with [z-item-name = "wet-shelf" or z-item-name = "dry-shelf" or z-item-name = "consumer-scale"] [
        let floor-to-agent-tc 0
        ifelse [z-item-name] of self = "dry-shelf" [
          set floor-to-agent-tc floor-to-cb-tc][
          set floor-to-agent-tc floor-to-ss-tc]
          set floor-introduction (floor-introduction + 1)
          let transfer (random-binomial (floor-conc) (floor-to-agent-tc))
          set z-listeria z-listeria + transfer
          set z-listeria-concentration (z-listeria / [z-area] of self)
        ]
      ]
  ]
end

to maintenance-introduction
   let y random-float 100
   if (y >= 82.7) [
     ask one-of zones [
       set maintenance-event maintenance-event + 1 ; total maintenance events
       let x count listeria-here
         ask self [
          set z-listeria (z-listeria + maintenance-load)
           set z-listeria-concentration (z-listeria / [z-area] of self)
           set z-maintenance z-maintenance + 1 ; maintenance event on agents
         ]
       if (([z-listeria] of self) > 0) and (x = 0) [
         hatch-listeria 1 [
           listeria-setup setxy xcor ycor
         ]
        ]
      ]
     ]
end

to roof-leak-introduction
    foreach sort-on [ who ] zones [[?1] -> ask ?1[
     ;print(word "roof leak agent: " who)
     let y random-float 100
     if (y <= (z-area / total-sa) * 3.9)[
       ;print(word "roofleak y: " y)
       set roof-leak-event roof-leak-event + 1 ;total roof leak events
       let x count listeria-here
       ask self [
         ifelse z-area < roof-leak-sa [
           ;print(word "roofleak z-area: " z-area)
           let rl-listeria ((rleak-load / roof-leak-sa) * [z-area] of self)
           ;print(word "rl-listeria: " rl-listeria)
           set z-listeria (z-listeria + rl-listeria)
           set z-listeria-concentration (z-listeria / [z-area] of self)
           ;print(word "rl-z-listeria-concentration: " z-listeria-concentration)
           set z-roof-leak z-roof-leak + 1
         ][
           set z-listeria (z-listeria + rleak-load)
           set z-listeria-concentration (z-listeria / [z-area] of self)
           set z-roof-leak z-roof-leak + 1 ; roof leak event for agents
         ]
        if (([z-listeria] of self) > 0) and (x = 0) [
         hatch-listeria 1 [
           listeria-setup setxy xcor ycor
         ]
        ]
       ]
      ]
     ]
  ]
end

to clean-cs-wet ; Scenario 10: increased cleaning on consumer scales in wet display area
    ask zones with [z-item-name = "consumer-scale" and z-location = "wet-display-area"][
    if random-float 100 < prob-cleanable-cln [
      set z-listeria (random-binomial (z-listeria) (all-cln-reduction))
      set z-listeria-concentration (z-listeria / [z-area] of self)
    ]
  ]
end

to clean-cs-dry ; Scenario 10: increased cleaning on consumer scales in dry display area
    ask zones with [z-item-name = "consumer-scale" and z-location = "dry-display-area"][
    if random-float 100 < prob-cleanable-cln [
      set z-listeria (random-binomial (z-listeria) (all-cln-reduction))
      set z-listeria-concentration (z-listeria / [z-area] of self)
    ]
  ]
end

to clean-dry
  ;Deep cleaning in dry shelves - no regular cleaning on wet shelves
  if dry-event = "DC" [
    ;print("dry-DC")
    ask zones with [z-location = "dry-display-area"][
      if random-float 100 < prob-cleanable-dcln [
        set z-listeria (random-binomial (z-listeria) (all-dcln-reduction))
        set z-listeria-concentration (z-listeria / [z-area] of self)
      ]
    ]
  ]
end

to clean-wet
  ;Cleaning in wet shelves
  if wet-event = "CL"[
      ;print("wet-CL")
      ask zones with [z-location = "wet-display-area" and z-listeria > 0 and z-cleanable? ] [
        if random-float 100 < prob-cleanable-cln [
          set z-listeria (random-binomial (z-listeria) (all-cln-reduction))
          set z-listeria-concentration (z-listeria / [z-area] of self)
        ]
      ]
     ]

  ;Deep cleaning in wet shelves
  if wet-event = "DC" [
       ;print("wet-DC")
       ask zones with [z-location = "wet-display-area"][
       if random-float 100 < prob-cleanable-dcln [
          set z-listeria (random-binomial (z-listeria) (all-dcln-reduction))
          set z-listeria-concentration (z-listeria / [z-area] of self)
        ]
       ]
     ]
end

to clean-cutting
  ;Cleaning in cutting station
  if cutting-event = "CL"[
      ;print("cutting-CL")
      ask zones with [z-location = "cutting-station" and z-listeria > 0 and z-cleanable? ] [
        if random-float 100 < prob-cleanable-dcln [ ; NOTE:cutting station agents are cleaned more thoroughly so that proper cleaning is more likely
          set z-listeria (random-binomial (z-listeria) (all-dcln-reduction))
          set z-listeria-concentration (z-listeria / [z-area] of self)
        ]
      ]
     ]
end

to clean-runner
  ;Cleaning in runners
  if runner-event = "CL"[
    ;print("storage-CL")
    ask zones with [z-item-name = "runner" and z-listeria > 0 and z-cleanable? ] [
      if random-float 100 < prob-cleanable-cln [
        set z-listeria (random-binomial (z-listeria) (all-cln-reduction))
        set z-listeria-concentration (z-listeria / [z-area] of self)
      ]
     ]
    ]
end

;;; these are reporter functions used throughout the code - mainly probability distributions - don't change - roll in n flooring
to-report random-binomial [n p]
;  is-integer (n)
  set n floor (n)
  report sum n-values n [ifelse-value (p > random-float 1) [1] [0]]
end

to-report random-in-range [low high]
  report low + random (high - low + 1)
end

to-report randomfloat-in-range [low high]
  report low + random-float (high - low)
end

to-report random-triangular [a-min a-mode a-max]
  ; Return a random value from a triangular distribution
  ; Method from https://en.wikipedia.org/wiki/Triangular_distribution#Generating_Triangular-distributed_random_variates
  ; Obtained 2015-11-27

  if (a-min > a-mode) or (a-mode > a-max) or (a-min >= a-max)
   [ error (word "Random-triangular received illegal parameters (min, mode, max): " a-min " " a-mode " " a-max) ]

  let a-rand random-float 1.0
  let F (a-mode - a-min) / (a-max - a-min)

  ifelse a-rand < F
  [ report a-min + sqrt (a-rand * (a-max - a-min) * (a-mode - a-min)) ]
  [ report a-max - sqrt ((1 - a-rand) * (a-max - a-min) * (a-max - a-mode)) ]

end

to-report random-pert [minval likeval maxval lambda]  ;;taken from internet at: http://stackoverflow.com/questions/30807377/netlogo-sampling-from-a-beta-pert-distribtuion
  ;use pert params to draw from a beta distribution
  if not (minval <= likeval and likeval <= maxval) [error "wrong argument ranking"]
  if (minval = likeval and likeval = maxval) [report minval] ;;handle trivial inputs
  let pert-var 1 / 36
  let pert-mean (maxval + lambda * likeval - 5 * minval) / (6 * (maxval - minval))
  let temp pert-mean * (1 - pert-mean) / pert-var
  let alpha1 pert-mean * (temp - 1)
  let alpha2 (1 - pert-mean) * (temp - 1)
  let x1 random-gamma alpha1 1
  let x2 random-gamma alpha2 1
  report (x1 / (x1 + x2)) * (maxval - minval) + minval
end

;;; these are functions to update colors on interface - can change if want a different color scheme
to p-water-recolor
  if (p-water != 0) and (p-water != 1) and (p-water != 5) and (p-water != 6) and (p-water != 35) [set pcolor (blue + 4.9 - p-water)]
  ;if (p-water = 3) [set pcolor blue + 4.9 - p-water]
  if (p-water <= 1) [set pcolor white]
  if (p-water = 0) [set pcolor black]
  if (p-water = 5) [set pcolor gray]
  if (p-water = 6) [set pcolor 9]
  if (p-water = 35) [set pcolor brown]
end

to p-traffic-recolor
  if (p-traffic != 0) and (p-water != 5) and (p-water != 6) and (p-water != 35) [set pcolor (green + 4.9 - p-traffic)]
  if (p-traffic = 0) [set pcolor black]
  if (p-traffic = 1) [set pcolor white]
  if (p-traffic = 5) [set pcolor gray]
  if (p-traffic = 6) [set pcolor 9]
  if (p-traffic = 35) [set pcolor brown]
end

to zone-recolor
  if z-category = 1 [set color (red)]
  if z-category = 2 [set color (orange)]
  if z-category = 3 [ set color (magenta)]
  if z-item-name = "employee" [set color (black)]
end

to is-integer [number]
  if floor number != number [error "Value given is not an integer!"]
end
@#$#@#$#@
GRAPHICS-WINDOW
400
15
658
424
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
49
0
79
1
1
1
ticks
30.0

BUTTON
25
10
99
49
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
118
11
190
50
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
25
295
82
340
zone 1
count zones with [(z-category = 1) and (z-listeria-concentration > 0)]
17
1
11

MONITOR
95
295
151
340
zone 2
count zones with [(z-category = 2 ) and (z-listeria-concentration > 0)]
0
1
11

PLOT
962
303
1317
608
Retail Listeria Population
Time (hr)
Listeria density (log10(cfu)/cm^2)
0.0
336.0
0.0
3.0
true
true
"" ""
PENS
"zone-1 " 1.0 0 -10899396 true "" "plot log(mean [z-listeria-concentration + 1e-1] of zones with [z-category = 1]) 10"
"zone-2" 1.0 0 -955883 true "" "plot log (mean [z-listeria-concentration + 1e-1] of zones with [z-category = 2]) 10"

CHOOSER
131
92
256
137
environment-view
environment-view
"water" "traffic"
1

MONITOR
180
460
290
505
cleanable + contam.
count zones with [(z-cleanable?) and (z-listeria-concentration > 0)]
0
1
11

MONITOR
294
459
425
504
not cleanable +  contam.
count zones with [(not z-cleanable?) and (z-listeria-concentration > 0)]
0
1
11

OUTPUT
795
82
938
114
14

PLOT
962
19
1316
290
Retail Listeria Prevalence
Time (hr)
Contaminated Sites
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"zones" 1.0 1 -16777216 true "" "plot ((count zones with [z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-listeria-concentration > 0.016 and z-area > 100 ] ) / count zones)"

MONITOR
25
350
105
395
zone-to-zone
zone-to-zone
17
1
11

MONITOR
380
515
452
560
cont. Food
introduction-food
0
1
11

MONITOR
25
241
82
286
Z(dry)
count zones with [z-water <= 1]
17
1
11

MONITOR
90
240
192
285
Z(visible water)
count zones with [z-water > 1 and z-water <= 2]
17
1
11

MONITOR
205
240
267
285
Z(moist)
count zones with [z-water > 2 and z-water <= 3]
17
1
11

MONITOR
25
460
85
505
floor
count patches with [p-listeria > 0]
0
1
11

MONITOR
115
350
183
395
z1-contacts
mean [z-contacts] of zones with [z-category = 1]
2
1
11

MONITOR
186
350
259
395
z1-transfers
mean [z-transfers] of zones with [z-category = 1]
2
1
11

SLIDER
25
53
257
86
time-of-simulation
time-of-simulation
1
4
4.0
1
1
weeks
HORIZONTAL

CHOOSER
24
92
127
137
detection-limit
detection-limit
1 10 100
0

SLIDER
25
145
255
178
numSamples
numSamples
0
100
5.0
1
1
samples/wk
HORIZONTAL

CHOOSER
25
185
172
230
sampling-strategy
sampling-strategy
"none" "all-day" "random-sample"
0

CHOOSER
190
185
377
230
sampling-sites
sampling-sites
"none" "Zone2" "Zone1"
0

MONITOR
165
295
302
340
mean zone CFU/sq. cm
mean [z-listeria-concentration] of zones with [z-listeria-concentration > 0]
2
1
11

MONITOR
455
515
557
560
cont. Food CFUs
sum-food-load
0
1
11

MONITOR
560
515
687
560
Food CFU transfered
sum-food-transfer
0
1
11

MONITOR
90
460
177
505
contam. sites
count zones with [z-listeria-concentration > 0 ]
0
1
11

MONITOR
280
240
337
285
z1-food
mean [z-food] of zones with [z-category = 1]
2
1
11

SLIDER
963
690
1135
723
local-seed
local-seed
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
1149
690
1321
723
scenario
scenario
0
49
5.0
1
1
NIL
HORIZONTAL

SWITCH
195
15
342
48
debug-messages
debug-messages
0
1
-1000

MONITOR
220
585
282
630
Door
[z-listeria] of a-zone 15
17
1
11

MONITOR
25
685
162
730
Employee (wet shelf)
[z-listeria] of a-zone 18
17
1
11

MONITOR
315
695
447
740
Cleaning equipment
[z-listeria-concentration] of a-zone 31
4
1
11

MONITOR
825
127
937
172
current-dry-event
dry-event
17
1
11

MONITOR
825
182
937
227
current-wet-event
wet-event
17
1
11

MONITOR
805
237
937
282
current-cutting-event
cutting-event
17
1
11

MONITOR
805
292
937
337
current-runner-event
runner-event
17
1
11

MONITOR
570
695
692
740
Consumer scale 2
[z-listeria] of a-zone 17
17
1
11

MONITOR
570
640
692
685
Consumer scale 1
[z-listeria] of a-zone 13
17
1
11

MONITOR
570
585
682
630
Dry shelves
[z-listeria] of a-zone 23
17
1
11

MONITOR
220
710
277
755
Runner
[z-listeria] of a-zone 14
17
1
11

MONITOR
25
635
157
680
Employee (storage)
[z-listeria] of a-zone 16
17
1
11

MONITOR
963
630
1040
675
Wet display
count zones with [(z-location = \"wet-display\") and (z-listeria-concentration > 0)]
17
1
11

MONITOR
1049
630
1121
675
Dry display
count zones with [(z-location = \"dry-display\") and (z-listeria > 0)]
17
1
11

MONITOR
1129
630
1221
675
Cutting station
count zones with [(z-location = \"chopping-station\") and (z-listeria-concentration > 0)]
17
1
11

MONITOR
1229
630
1286
675
Storage
count zones with [(z-location = \"storage\") and (z-listeria-concentration > 0)]
17
1
11

MONITOR
315
750
372
795
Sink
[z-listeria-concentration] of a-zone 7
17
1
11

MONITOR
25
740
202
785
Employee (cutting station)
[z-listeria] of a-zone 10
6
1
11

MONITOR
425
585
537
630
Handwash station
[z-listeria] of a-zone 8
17
1
11

MONITOR
425
640
503
685
Fruit basket
[z-listeria-concentration] of a-zone 5
17
1
11

MONITOR
385
750
482
795
Employee scale
[z-listeria-concentration] of a-zone 6
17
1
11

MONITOR
700
515
807
560
NIL
introduction-food
17
1
11

MONITOR
828
20
937
65
Operation Time
operation-time
17
1
11

MONITOR
753
20
810
65
NIL
day
17
1
11

MONITOR
679
20
736
65
NIL
week
17
1
11

MONITOR
700
695
847
740
Water sprinkler head
[z-listeria] of a-zone 56
17
1
11

MONITOR
25
585
177
630
Employee (dry shelves)
[z-listeria] of a-zone 11
17
1
11

MONITOR
700
585
782
630
Wet shelf
[z-listeria] of a-zone 35
17
1
11

MONITOR
460
695
537
740
Work table
[z-listeria-concentration] of a-zone 32
17
1
11

MONITOR
315
585
413
630
Cutting board
[z-listeria-concentration] of a-zone 3
17
1
11

MONITOR
315
640
407
685
Cutting knife
[z-listeria-concentration] of a-zone 4
17
1
11

PLOT
1332
19
1690
289
Listeria prevalence by locations
Time (hr)
Prevalence
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Storage" 1.0 1 -4539718 true "" "plot ((count zones with [z-location = \"storage\" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = \"storage\" and z-listeria-concentration > 0.016 and z-area > 100 ] ) / count zones with [z-location = \"storage\"])"
"Wet shelf" 1.0 1 -13791810 true "" "plot ((count zones with [z-location = \"wet-display\" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = \"wet-display\" and z-listeria-concentration > 0.016 and z-area > 100 ] ) / count zones with [z-location = \"wet-display\"])"
"Dry shelf" 1.0 1 -10603201 true "" "plot ((count zones with [z-location = \"dry-display\" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = \"dry-display\" and z-listeria-concentration > 0.016 and z-area > 100 ] ) / count zones with [z-location = \"dry-display\"])"
"Cutting station" 1.0 1 -10899396 true "" "plot ((count zones with [z-location = \"cutting-station\" and z-listeria-concentration > 0.1 and z-area <= 100 ] + count zones with [z-location = \"cutting-station\" and z-listeria-concentration > 0.016 and z-area > 100 ] ) / count zones with [z-location = \"cutting-station\"])"

PLOT
1332
304
1692
604
Literia Population by Locations
Time (hr)
Listeria density (log(cfu)/cm^2)
0.0
336.0
0.0
3.0
true
true
"" ""
PENS
"Storage" 1.0 0 -4539718 true "" "plot log(mean [z-listeria-concentration + 1e-1] of zones with [z-location = \"storage\"]) 10"
"Wet shelf" 1.0 0 -13791810 true "" "plot log(mean [z-listeria-concentration + 1e-1] of zones with [z-location = \"wet-display\"]) 10"
"Dry shelf" 1.0 0 -12440034 true "" "plot log(mean [z-listeria-concentration + 1e-1] of zones with [z-location = \"dry-display\"]) 10"
"Cutting station" 1.0 0 -10899396 true "" "plot log(mean [z-listeria-concentration + 1e-1] of zones with [z-location = \"cutting-station\"]) 10"

MONITOR
820
515
947
560
NIL
floor-introduction
17
1
11

MONITOR
498
459
626
504
NIL
maintenance-event
17
1
11

MONITOR
648
459
757
504
NIL
roof-leak-event
17
1
11

MONITOR
570
755
802
800
Consumer Introduction Wet Shelves
consumer-intro-wet
17
1
11

MONITOR
820
755
1052
800
Consumer Introduction Dry Shelves
consumer-intro-dry
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Retail_CA" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>all-time-detect-list</metric>
    <metric>all-max-detect-bout-list</metric>
    <metric>all-time-contaminated-list</metric>
    <metric>all-max-contam-bout-list</metric>
    <metric>all-contacts-list</metric>
    <metric>all-prev-list</metric>
    <metric>all-transfers-list</metric>
    <metric>all-conc-list</metric>
    <metric>all-count-list</metric>
    <metric>all-maintenance-events-list</metric>
    <metric>all-roof-leak-events-list</metric>
    <enumeratedValueSet variable="random-seed">
      <value value="4519"/>
    </enumeratedValueSet>
    <steppedValueSet variable="local-seed" first="1" step="1" last="1000"/>
  </experiment>
  <experiment name="Retail_Scenario" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>collect-time</metric>
    <metric>all-count-list</metric>
    <metric>all-prev-list</metric>
    <metric>all-conc-list</metric>
    <metric>food-conc</metric>
    <metric>food-tc</metric>
    <metric>consumer-tc</metric>
    <metric>consumer-prev</metric>
    <metric>consumer-intro-wet</metric>
    <metric>consumer-intro-dry</metric>
    <metric>consumer-load-wet</metric>
    <metric>consumer-load-dry</metric>
    <metric>introduction-food</metric>
    <metric>sum-food-load</metric>
    <metric>floor-conc</metric>
    <metric>zone-to-zone</metric>
    <metric>introduction-food</metric>
    <metric>maintenance-event</metric>
    <metric>roof-leak-event</metric>
    <metric>mu-max-rt</metric>
    <metric>mu-max-at</metric>
    <metric>all-box-prevalence</metric>
    <metric>p11</metric>
    <metric>p12</metric>
    <metric>p21</metric>
    <metric>p22</metric>
    <metric>tc11</metric>
    <metric>tc12</metric>
    <metric>tc13</metric>
    <metric>tc14</metric>
    <metric>tc15</metric>
    <metric>tc21</metric>
    <metric>tc22</metric>
    <metric>tc24</metric>
    <metric>tc25</metric>
    <metric>tc31</metric>
    <metric>tc34</metric>
    <metric>tc41</metric>
    <metric>tc42</metric>
    <metric>tc43</metric>
    <metric>tc51</metric>
    <metric>tc52</metric>
    <enumeratedValueSet variable="random-seed">
      <value value="4519"/>
    </enumeratedValueSet>
    <steppedValueSet variable="local-seed" first="1" step="1" last="1000"/>
  </experiment>
  <experiment name="Retail_Baseline_Result" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>all-prev-list</metric>
    <metric>cb-prev-list</metric>
    <metric>ck-prev-list</metric>
    <metric>cs-prev-list</metric>
    <metric>sink-prev-list</metric>
    <metric>hsink-prev-list</metric>
    <metric>employee-prev-list</metric>
    <metric>runner-prev-list</metric>
    <metric>wets-prev-list</metric>
    <metric>wsh-prev-list</metric>
    <metric>drys-prev-list</metric>
    <metric>z1-all-prev-list</metric>
    <metric>z2-all-prev-list</metric>
    <metric>cutting-all-prev-list</metric>
    <metric>wet-all-prev-list</metric>
    <metric>dry-all-prev-list</metric>
    <metric>storage-all-prev-list</metric>
    <metric>all-count-list</metric>
    <metric>all-conc-list</metric>
    <metric>all-time-contaminated-list</metric>
    <metric>all-max-consec-contam-list</metric>
    <metric>all-time-detect-list</metric>
    <metric>all-max-consec-detect-list</metric>
    <metric>all-contacts-list</metric>
    <metric>all-transfers-list</metric>
    <metric>cutting-all-conc-list</metric>
    <metric>cutting-all-count-list</metric>
    <metric>wet-all-conc-list</metric>
    <metric>wet-all-count-list</metric>
    <metric>dry-all-conc-list</metric>
    <metric>dry-all-count-list</metric>
    <metric>storage-all-conc-list</metric>
    <metric>storage-all-count-list</metric>
    <metric>z1-all-conc-list</metric>
    <metric>z1-all-count-list</metric>
    <metric>z2-all-conc-list</metric>
    <metric>z2-all-count-list</metric>
    <metric>all-maintenance-events-list</metric>
    <metric>all-roof-leak-events-list</metric>
    <metric>food-conc</metric>
    <metric>food-tc</metric>
    <metric>consumer-tc</metric>
    <metric>consumer-prev</metric>
    <metric>consumer-intro-wet</metric>
    <metric>consumer-intro-dry</metric>
    <metric>consumer-load-wet</metric>
    <metric>consumer-load-dry</metric>
    <metric>introduction-food</metric>
    <metric>sum-food-load</metric>
    <metric>floor-conc</metric>
    <metric>zone-to-zone</metric>
    <metric>maintenance-event</metric>
    <metric>roof-leak-event</metric>
    <metric>mu-max-rt</metric>
    <metric>mu-max-at</metric>
    <metric>all-box-prevalence</metric>
    <metric>p11</metric>
    <metric>p12</metric>
    <metric>p21</metric>
    <metric>p22</metric>
    <metric>tc11</metric>
    <metric>tc12</metric>
    <metric>tc13</metric>
    <metric>tc14</metric>
    <metric>tc15</metric>
    <metric>tc21</metric>
    <metric>tc22</metric>
    <metric>tc24</metric>
    <metric>tc25</metric>
    <metric>tc31</metric>
    <metric>tc34</metric>
    <metric>tc41</metric>
    <metric>tc42</metric>
    <metric>tc43</metric>
    <metric>tc51</metric>
    <metric>tc52</metric>
    <enumeratedValueSet variable="random-seed">
      <value value="4519"/>
    </enumeratedValueSet>
    <steppedValueSet variable="local-seed" first="1" step="1" last="1000"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
