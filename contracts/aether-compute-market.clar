;; ---
;; Contract: aether-compute-market.clar
;; Purpose:  Decentralized Compute Credit Marketplace
;; Author:   Abu
;; ---

(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-NOT-PROVIDER (err u101))
(define-constant ERR-INSUFFICIENT-CREDIT (err u102))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u103))
(define-constant ERR-CREDIT-EXPIRED (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-NOT-REGISTERED (err u106))

;; ------------------------------------------------------------
;; Global State
;; ------------------------------------------------------------

(define-data-var admin principal tx-sender)
(define-data-var total-credits uint u0)
(define-data-var credit-price uint u10000) ;; 10,000 microSTX per credit
(define-data-var provider-stake uint u50000) ;; minimum stake for providers

;; ------------------------------------------------------------
;; Data Maps
;; ------------------------------------------------------------

(define-map providers
  { provider: principal }
  {
    active: bool,
    stake: uint,
    registered-at: uint
  }
)

(define-map user-credits
  { user: principal }
  {
    credits: uint,
    expires-at: uint
  }
)

;; ------------------------------------------------------------
;; ------------------------------------------------------------
;; Helper Functions
;; ------------------------------------------------------------

(define-private (only-admin)
  (if (is-eq tx-sender (var-get admin))
      (ok true)
      ERR-NOT-ADMIN))

(define-private (only-provider)
  (let ((prov (map-get? providers { provider: tx-sender })))
    (match prov p
      (if (get active p)
          (ok true)
          ERR-NOT-PROVIDER)
      ERR-NOT-REGISTERED)))

(define-private (current-block) burn-block-height)

;; ------------------------------------------------------------
;; ADMIN
;; ------------------------------------------------------------

(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (ok true))
    ERR-NOT-ADMIN))

(define-public (set-credit-price (new-price uint))
  (if (is-eq tx-sender (var-get admin))
    (ok (var-set credit-price new-price))
    ERR-NOT-ADMIN))

;; ------------------------------------------------------------
;; PROVIDER MANAGEMENT
;; ------------------------------------------------------------

(define-public (register-provider)
  (begin
    (try! (stx-transfer? (var-get provider-stake) tx-sender (as-contract tx-sender)))
    (map-set providers { provider: tx-sender }
      { active: true, stake: (var-get provider-stake), registered-at: (current-block) })
    (ok true)))

;; ------------------------------------------------------------
;; USER FUNCTIONS
;; ------------------------------------------------------------

(define-public (buy-credits (amount uint))
  (if (<= amount u0)
      ERR-INVALID-AMOUNT
      (let ((cost (* amount (var-get credit-price))))
        (begin
          (try! (stx-transfer? cost tx-sender (as-contract tx-sender)))
          (match (map-get? user-credits { user: tx-sender })
            e
            (let ((new-total (+ (get credits e) amount))
                  (expiry (+ (current-block) u720)))
              (begin
                (map-set user-credits { user: tx-sender }
                  { credits: new-total, expires-at: expiry })
                (ok new-total)))
            (begin
              (map-set user-credits { user: tx-sender }
                { credits: amount, expires-at: (+ (current-block) u720) })
              (ok amount)))))))

(define-public (spend-credits (amount uint) (provider principal))
  (if (<= amount u0)
      ERR-INVALID-AMOUNT
      (match (map-get? user-credits { user: tx-sender })
        a
        (if (>= (get expires-at a) (current-block))
            (if (>= (get credits a) amount)
                (begin
                  (map-set user-credits { user: tx-sender }
                    { credits: (- (get credits a) amount), expires-at: (get expires-at a) })
                  (try! (stx-transfer? (* amount (var-get credit-price)) (as-contract tx-sender) provider))
                  (ok true))
                ERR-INSUFFICIENT-CREDIT)
            ERR-CREDIT-EXPIRED)
        ERR-ACCOUNT-NOT-FOUND)))

;; ------------------------------------------------------------
;; READ-ONLY
;; ------------------------------------------------------------

(define-read-only (get-user-credits (user principal))
  (default-to { credits: u0, expires-at: u0 } (map-get? user-credits { user: user })))

(define-read-only (get-provider (provider principal))
  (default-to { active: false, stake: u0, registered-at: u0 } (map-get? providers { provider: provider })))

(define-read-only (get-config)
  {
    admin: (var-get admin),
    credit-price: (var-get credit-price),
    provider-stake: (var-get provider-stake),
    total-credits: (var-get total-credits)
  })
