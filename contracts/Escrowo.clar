;; Decentralized Escrow Service Smart Contract
;; Enables secure peer-to-peer transactions with secure escrow protection

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-escrow-completed (err u104))
(define-constant err-escrow-disputed (err u105))
(define-constant err-insufficient-funds (err u106))

;; Data Variables
(define-data-var escrow-counter uint u0)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points (250/10000)

;; Data Maps
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    description: (string-ascii 256),
    status: (string-ascii 20),
    created-at: uint,
    dispute-reason: (optional (string-ascii 512))
  }
)

(define-map escrow-balances
  { escrow-id: uint }
  { balance: uint }
)

;; Read-only functions
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

(define-read-only (get-escrow-balance (escrow-id uint))
  (map-get? escrow-balances { escrow-id: escrow-id })
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (get-escrow-counter)
  (var-get escrow-counter)
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

;; Private functions
(define-private (is-escrow-participant (escrow-id uint) (user principal))
  (match (map-get? escrows { escrow-id: escrow-id })
    escrow-data (or (is-eq user (get buyer escrow-data))
                    (is-eq user (get seller escrow-data)))
    false
  )
)

;; Public functions
(define-public (create-escrow (seller principal) (amount uint) (description (string-ascii 256)))
  (let (
    (escrow-id (+ (var-get escrow-counter) u1))
    (current-block stacks-block-height)
  )
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set escrows
      { escrow-id: escrow-id }
      {
        buyer: tx-sender,
        seller: seller,
        amount: amount,
        description: description,
        status: "active",
        created-at: current-block,
        dispute-reason: none
      }
    )
    
    (map-set escrow-balances
      { escrow-id: escrow-id }
      { balance: amount }
    )
    
    (var-set escrow-counter escrow-id)
    (ok escrow-id)
  )
)

(define-public (release-funds (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-not-found))
    (escrow-balance (unwrap! (map-get? escrow-balances { escrow-id: escrow-id }) err-not-found))
    (amount (get balance escrow-balance))
    (platform-fee (calculate-platform-fee amount))
    (seller-amount (- amount platform-fee))
  )
    (asserts! (is-eq tx-sender (get buyer escrow-data)) err-unauthorized)
    (asserts! (is-eq (get status escrow-data) "active") err-escrow-completed)
    
    (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller escrow-data))))
    (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
    
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { status: "completed" })
    )
    
    (map-set escrow-balances
      { escrow-id: escrow-id }
      { balance: u0 }
    )
    
    (ok true)
  )
)

(define-public (dispute-escrow (escrow-id uint) (reason (string-ascii 512)))
  (let (
    (escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-not-found))
  )
    (asserts! (is-escrow-participant escrow-id tx-sender) err-unauthorized)
    (asserts! (is-eq (get status escrow-data) "active") err-escrow-completed)
    
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { 
        status: "disputed",
        dispute-reason: (some reason)
      })
    )
    
    (ok true)
  )
)

(define-public (resolve-dispute (escrow-id uint) (release-to-seller bool))
  (let (
    (escrow-data (unwrap! (map-get? escrows { escrow-id: escrow-id }) err-not-found))
    (escrow-balance (unwrap! (map-get? escrow-balances { escrow-id: escrow-id }) err-not-found))
    (amount (get balance escrow-balance))
    (platform-fee (calculate-platform-fee amount))
    (net-amount (- amount platform-fee))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status escrow-data) "disputed") err-escrow-disputed)
    
    (if release-to-seller
      (try! (as-contract (stx-transfer? net-amount tx-sender (get seller escrow-data))))
      (try! (as-contract (stx-transfer? net-amount tx-sender (get buyer escrow-data))))
    )
    
    (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
    
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow-data { status: "resolved" })
    )
    
    (map-set escrow-balances
      { escrow-id: escrow-id }
      { balance: u0 }
    )
    
    (ok true)
  )
)

(define-public (set-platform-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u1000) err-invalid-amount) ;; Max 10%
    (var-set platform-fee-rate new-rate)
    (ok true)
  )
)