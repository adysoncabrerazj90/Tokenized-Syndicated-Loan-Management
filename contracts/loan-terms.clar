;; loan-terms.clar
;; This contract records financing conditions and covenants

(define-data-var admin principal tx-sender)
(define-data-var loan-id-counter uint u0)

;; Map to store loan terms
(define-map loans uint {
  borrower: principal,
  amount: uint,
  interest-rate: uint,  ;; basis points (e.g., 500 = 5.00%)
  term-length: uint,    ;; in days
  start-block: uint,
  covenants: (string-utf8 500),
  active: bool
})

;; Map to track lender participation in loans
(define-map loan-participations (tuple (loan-id uint) (lender principal)) {
  amount: uint,
  participation-date: uint
})

;; Function to create a new loan (admin only)
(define-public (create-loan
                (borrower principal)
                (amount uint)
                (interest-rate uint)
                (term-length uint)
                (covenants (string-utf8 500)))
  (let ((new-loan-id (+ (var-get loan-id-counter) u1)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u1))
      (var-set loan-id-counter new-loan-id)
      (ok (map-set loans new-loan-id {
        borrower: borrower,
        amount: amount,
        interest-rate: interest-rate,
        term-length: term-length,
        start-block: block-height,
        covenants: covenants,
        active: true
      }))
    )
  )
)

;; Function to add a lender participation to a loan
(define-public (add-participation (loan-id uint) (lender principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (is-some (map-get? loans loan-id)) (err u2))
    (ok (map-set loan-participations {loan-id: loan-id, lender: lender} {
      amount: amount,
      participation-date: block-height
    }))
  )
)

;; Function to get loan details
(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans loan-id)
)

;; Function to get lender participation details
(define-read-only (get-participation-details (loan-id uint) (lender principal))
  (map-get? loan-participations {loan-id: loan-id, lender: lender})
)

;; Function to close a loan (admin only)
(define-public (close-loan (loan-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (is-some (map-get? loans loan-id)) (err u2))
    (ok (map-set loans loan-id
      (merge (unwrap-panic (map-get? loans loan-id))
             { active: false })))
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (var-set admin new-admin))
  )
)
