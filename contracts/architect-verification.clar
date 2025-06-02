;; Architect Verification Contract
;; Validates quantum architecture practitioners

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-architects
  { architect: principal }
  {
    verified-at: uint,
    certification-level: (string-ascii 20),
    specialization: (string-ascii 50),
    active: bool
  }
)

(define-map architect-credentials
  { architect: principal }
  {
    education: (string-ascii 100),
    experience-years: uint,
    quantum-projects: uint
  }
)

;; Read-only functions
(define-read-only (is-verified-architect (architect principal))
  (match (map-get? verified-architects { architect: architect })
    architect-data (get active architect-data)
    false
  )
)

(define-read-only (get-architect-info (architect principal))
  (map-get? verified-architects { architect: architect })
)

(define-read-only (get-architect-credentials (architect principal))
  (map-get? architect-credentials { architect: architect })
)

;; Public functions
(define-public (verify-architect
  (architect principal)
  (certification-level (string-ascii 20))
  (specialization (string-ascii 50))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-architects { architect: architect })) ERR_ALREADY_VERIFIED)

    (map-set verified-architects
      { architect: architect }
      {
        verified-at: block-height,
        certification-level: certification-level,
        specialization: specialization,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (add-credentials
  (education (string-ascii 100))
  (experience-years uint)
  (quantum-projects uint)
)
  (begin
    (map-set architect-credentials
      { architect: tx-sender }
      {
        education: education,
        experience-years: experience-years,
        quantum-projects: quantum-projects
      }
    )
    (ok true)
  )
)

(define-public (revoke-verification (architect principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-architects { architect: architect })) ERR_NOT_FOUND)

    (map-set verified-architects
      { architect: architect }
      (merge
        (unwrap-panic (map-get? verified-architects { architect: architect }))
        { active: false }
      )
    )
    (ok true)
  )
)
