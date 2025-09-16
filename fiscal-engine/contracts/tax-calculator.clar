;; Contract owner and admin controls
(define-constant CONTRACT-ADMIN tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-JURISDICTION (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INVALID-TAX-TYPE (err u103))
(define-constant ERR-ALREADY-CALCULATED (err u104))
(define-constant ERR-CALCULATION-NOT-FOUND (err u105))

;; Tax types and jurisdictions
(define-constant TAX-TYPE-INCOME u1)
(define-constant TAX-TYPE-CAPITAL-GAINS u2)
(define-constant TAX-TYPE-TRANSACTION u3)
(define-constant JURISDICTION-US u1)
(define-constant JURISDICTION-EU u2)
(define-constant JURISDICTION-UK u3)

;; Tax calculation storage
(define-map tax-calculations
  { calculation-id: uint }
  {
    taxpayer: principal,
    jurisdiction: uint,
    tax-type: uint,
    gross-amount: uint,
    tax-amount: uint,
    net-amount: uint,
    tax-rate: uint,
    calculation-date: uint,
    is-paid: bool
  }
)

;; Tax rates by jurisdiction and type (in basis points, 10000 = 100%)
(define-map tax-rates
  { jurisdiction: uint, tax-type: uint }
  { rate: uint, threshold: uint, updated-block: uint }
)

;; Taxpayer information
(define-map taxpayers
  { taxpayer: principal }
  {
    jurisdiction: uint,
    total-income: uint,
    total-taxes-paid: uint,
    last-filing: uint,
    compliance-status: bool
  }
)

;; Annual tax summaries
(define-map annual-summaries
  { taxpayer: principal, tax-year: uint }
  {
    total-income: uint,
    total-capital-gains: uint,
    total-taxes-owed: uint,
    total-taxes-paid: uint,
    filing-status: bool
  }
)

;; Contract state
(define-data-var next-calculation-id uint u1)
(define-data-var current-tax-year uint u2024)
(define-data-var total-tax-collected uint u0)

;; Initialize default tax rates
(map-set tax-rates { jurisdiction: JURISDICTION-US, tax-type: TAX-TYPE-INCOME } 
         { rate: u2200, threshold: u0, updated-block: block-height })
(map-set tax-rates { jurisdiction: JURISDICTION-US, tax-type: TAX-TYPE-CAPITAL-GAINS } 
         { rate: u1500, threshold: u0, updated-block: block-height })
(map-set tax-rates { jurisdiction: JURISDICTION-US, tax-type: TAX-TYPE-TRANSACTION } 
         { rate: u25, threshold: u0, updated-block: block-height })

;; Calculate tax amount based on jurisdiction and type
(define-private (calculate-tax-amount (amount uint) (jurisdiction uint) (tax-type uint))
  (let ((rate-data (map-get? tax-rates { jurisdiction: jurisdiction, tax-type: tax-type })))
    (match rate-data
      rate-info
        (let ((rate (get rate rate-info))
              (threshold (get threshold rate-info)))
          (if (>= amount threshold)
            (/ (* amount rate) u10000)
            u0))
      u0)))

;; Register taxpayer in system
(define-public (register-taxpayer (jurisdiction uint))
  (begin
    (asserts! (>= jurisdiction JURISDICTION-US) ERR-INVALID-JURISDICTION)
    (asserts! (<= jurisdiction JURISDICTION-UK) ERR-INVALID-JURISDICTION)
    
    (map-set taxpayers
      { taxpayer: tx-sender }
      {
        jurisdiction: jurisdiction,
        total-income: u0,
        total-taxes-paid: u0,
        last-filing: u0,
        compliance-status: true
      })
    
    (ok true)))

;; Calculate tax for a transaction
(define-public (calculate-tax (amount uint) (tax-type uint))
  (let ((calculation-id (var-get next-calculation-id))
        (taxpayer-data (map-get? taxpayers { taxpayer: tx-sender })))
    
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= tax-type TAX-TYPE-INCOME) ERR-INVALID-TAX-TYPE)
    (asserts! (<= tax-type TAX-TYPE-TRANSACTION) ERR-INVALID-TAX-TYPE)
    
    (let ((jurisdiction (match taxpayer-data
                          data (get jurisdiction data)
                          JURISDICTION-US))
          (tax-amount (calculate-tax-amount amount jurisdiction tax-type))
          (net-amount (- amount tax-amount)))
      
      ;; Store calculation
      (map-set tax-calculations
        { calculation-id: calculation-id }
        {
          taxpayer: tx-sender,
          jurisdiction: jurisdiction,
          tax-type: tax-type,
          gross-amount: amount,
          tax-amount: tax-amount,
          net-amount: net-amount,
          tax-rate: (unwrap-panic (get rate (map-get? tax-rates { jurisdiction: jurisdiction, tax-type: tax-type }))),
          calculation-date: block-height,
          is-paid: false
        })
      
      ;; Update next ID
      (var-set next-calculation-id (+ calculation-id u1))
      
      (ok { calculation-id: calculation-id, tax-amount: tax-amount, net-amount: net-amount }))))

;; Pay calculated tax
(define-public (pay-tax (calculation-id uint))
  (let ((calc-data (unwrap! (map-get? tax-calculations { calculation-id: calculation-id }) ERR-CALCULATION-NOT-FOUND)))
    (asserts! (is-eq (get taxpayer calc-data) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-paid calc-data)) ERR-ALREADY-CALCULATED)
    
    (let ((tax-amount (get tax-amount calc-data)))
      ;; Transfer tax payment to contract
      (try! (stx-transfer? tax-amount tx-sender (as-contract tx-sender)))
      
      ;; Mark as paid
      (map-set tax-calculations
        { calculation-id: calculation-id }
        (merge calc-data { is-paid: true }))
      
      ;; Update taxpayer totals
      (match (map-get? taxpayers { taxpayer: tx-sender })
        taxpayer-data
          (map-set taxpayers
            { taxpayer: tx-sender }
            (merge taxpayer-data {
              total-taxes-paid: (+ (get total-taxes-paid taxpayer-data) tax-amount),
              total-income: (+ (get total-income taxpayer-data) (get gross-amount calc-data))
            }))
        true)
      
      ;; Update contract totals
      (var-set total-tax-collected (+ (var-get total-tax-collected) tax-amount))
      
      (ok true))))

;; File annual tax return
(define-public (file-annual-return (tax-year uint) (total-income uint) (total-capital-gains uint))
  (let ((taxpayer-data (unwrap! (map-get? taxpayers { taxpayer: tx-sender }) ERR-NOT-AUTHORIZED)))
    (asserts! (> tax-year u2020) ERR-INVALID-AMOUNT)
    (asserts! (<= tax-year (var-get current-tax-year)) ERR-INVALID-AMOUNT)
    
    (let ((jurisdiction (get jurisdiction taxpayer-data))
          (income-tax (calculate-tax-amount total-income jurisdiction TAX-TYPE-INCOME))
          (capital-gains-tax (calculate-tax-amount total-capital-gains jurisdiction TAX-TYPE-CAPITAL-GAINS))
          (total-tax-owed (+ income-tax capital-gains-tax)))
      
      ;; Create annual summary
      (map-set annual-summaries
        { taxpayer: tx-sender, tax-year: tax-year }
        {
          total-income: total-income,
          total-capital-gains: total-capital-gains,
          total-taxes-owed: total-tax-owed,
          total-taxes-paid: (get total-taxes-paid taxpayer-data),
          filing-status: true
        })
      
      ;; Update taxpayer filing status
      (map-set taxpayers
        { taxpayer: tx-sender }
        (merge taxpayer-data { last-filing: tax-year }))
      
      (ok { total-tax-owed: total-tax-owed, income-tax: income-tax, capital-gains-tax: capital-gains-tax }))))

;; Admin function to update tax rates
(define-public (update-tax-rate (jurisdiction uint) (tax-type uint) (new-rate uint) (threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u10000) ERR-INVALID-AMOUNT)
    
    (map-set tax-rates
      { jurisdiction: jurisdiction, tax-type: tax-type }
      { rate: new-rate, threshold: threshold, updated-block: block-height })
    
    (ok true)))

;; Get tax calculation details
(define-read-only (get-calculation (calculation-id uint))
  (map-get? tax-calculations { calculation-id: calculation-id }))

;; Get taxpayer information
(define-read-only (get-taxpayer-info (taxpayer principal))
  (map-get? taxpayers { taxpayer: taxpayer }))

;; Get annual summary
(define-read-only (get-annual-summary (taxpayer principal) (tax-year uint))
  (map-get? annual-summaries { taxpayer: taxpayer, tax-year: tax-year }))

;; Get current tax rate
(define-read-only (get-tax-rate (jurisdiction uint) (tax-type uint))
  (map-get? tax-rates { jurisdiction: jurisdiction, tax-type: tax-type }))

;; Calculate estimated tax for amount
(define-read-only (estimate-tax (amount uint) (jurisdiction uint) (tax-type uint))
  (let ((tax-amount (calculate-tax-amount amount jurisdiction tax-type)))
    { 
      gross-amount: amount,
      estimated-tax: tax-amount,
      net-amount: (- amount tax-amount)
    }))

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-calculations: (- (var-get next-calculation-id) u1),
    total-tax-collected: (var-get total-tax-collected),
    current-tax-year: (var-get current-tax-year)
  })