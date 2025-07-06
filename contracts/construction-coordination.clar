;; Construction Coordination Contract
;; Handles quantum architecture construction

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_PROJECT_NOT_FOUND (err u301))
(define-constant ERR_INVALID_PHASE (err u302))
(define-constant ERR_DESIGN_NOT_APPROVED (err u303))

;; Data structures
(define-map construction-projects
  { project-id: uint }
  {
    design-id: uint,
    contractor: principal,
    project-manager: principal,
    current-phase: (string-ascii 30),
    start-date: uint,
    estimated-completion: uint,
    actual-completion: (optional uint),
    budget: uint,
    spent: uint
  }
)

(define-map project-phases
  { project-id: uint, phase: (string-ascii 30) }
  {
    completed: bool,
    completion-date: (optional uint),
    quality-score: (optional uint),
    notes: (string-ascii 200)
  }
)

(define-data-var next-project-id uint u1)

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? construction-projects { project-id: project-id })
)

(define-read-only (get-phase-status (project-id uint) (phase (string-ascii 30)))
  (map-get? project-phases { project-id: project-id, phase: phase })
)

(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Public functions
(define-public (start-construction
  (design-id uint)
  (contractor principal)
  (project-manager principal)
  (estimated-completion uint)
  (budget uint)
)
  (let ((project-id (var-get next-project-id)))
    (begin
      ;; Note: In a real implementation, we'd verify design approval
      ;; (asserts! (contract-call? .design-protocol is-design-approved design-id) ERR_DESIGN_NOT_APPROVED)

      (map-set construction-projects
        { project-id: project-id }
        {
          design-id: design-id,
          contractor: contractor,
          project-manager: project-manager,
          current-phase: "foundation",
          start-date: block-height,
          estimated-completion: estimated-completion,
          actual-completion: none,
          budget: budget,
          spent: u0
        }
      )

      ;; Initialize phases
      (map-set project-phases
        { project-id: project-id, phase: "foundation" }
        { completed: false, completion-date: none, quality-score: none, notes: "" }
      )

      (var-set next-project-id (+ project-id u1))
      (ok project-id)
    )
  )
)

(define-public (complete-phase
  (project-id uint)
  (phase (string-ascii 30))
  (quality-score uint)
  (notes (string-ascii 200))
)
  (let ((project (unwrap! (map-get? construction-projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND)))
    (begin
      (asserts!
        (or
          (is-eq tx-sender (get contractor project))
          (is-eq tx-sender (get project-manager project))
        )
        ERR_UNAUTHORIZED
      )

      (map-set project-phases
        { project-id: project-id, phase: phase }
        {
          completed: true,
          completion-date: (some block-height),
          quality-score: (some quality-score),
          notes: notes
        }
      )
      (ok true)
    )
  )
)

(define-public (update-budget-spent
  (project-id uint)
  (amount uint)
)
  (let ((project (unwrap! (map-get? construction-projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get project-manager project)) ERR_UNAUTHORIZED)

      (map-set construction-projects
        { project-id: project-id }
        (merge project { spent: (+ (get spent project) amount) })
      )
      (ok true)
    )
  )
)
