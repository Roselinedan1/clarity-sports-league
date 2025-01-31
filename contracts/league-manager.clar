;; Define data storage
(define-map teams 
    principal 
    {name: (string-ascii 50), wins: uint, losses: uint, draws: uint}
)

(define-map matches 
    uint 
    {home-team: principal, away-team: principal, home-score: uint, away-score: uint, completed: bool}
)

(define-data-var match-nonce uint u0)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-team-exists (err u101))
(define-constant err-team-not-found (err u102))
(define-constant err-match-not-found (err u103))
(define-constant err-match-already-completed (err u104))

;; Register a new team
(define-public (register-team (team-name (string-ascii 50)))
    (let ((team-data {name: team-name, wins: u0, losses: u0, draws: u0}))
        (if (is-some (get-team-info tx-sender))
            err-team-exists
            (ok (map-set teams tx-sender team-data))
        )
    )
)

;; Schedule a new match
(define-public (schedule-match (home-team principal) (away-team principal))
    (let ((match-id (var-get match-nonce)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set matches match-id 
                    {home-team: home-team, 
                     away-team: away-team, 
                     home-score: u0, 
                     away-score: u0, 
                     completed: false}
                )
                (var-set match-nonce (+ match-id u1))
                (ok match-id)
            )
            err-owner-only
        )
    )
)

;; Record match result
(define-public (record-match-result (match-id uint) (home-score uint) (away-score uint))
    (let (
        (match (get-match match-id))
        (home-team (get home-team (unwrap! match err-match-not-found)))
        (away-team (get away-team (unwrap! match err-match-not-found)))
    )
        (if (and (is-eq tx-sender contract-owner) (not (get completed (unwrap! match err-match-not-found))))
            (begin
                (try! (update-team-stats home-team away-team home-score away-score))
                (map-set matches match-id 
                    (merge (unwrap! match err-match-not-found) 
                        {home-score: home-score, 
                         away-score: away-score, 
                         completed: true})
                )
                (ok true)
            )
            err-owner-only
        )
    )
)

;; Helper function to update team statistics
(define-private (update-team-stats (home-team principal) (away-team principal) (home-score uint) (away-score uint))
    (let (
        (home-data (unwrap! (get-team-info home-team) err-team-not-found))
        (away-data (unwrap! (get-team-info away-team) err-team-not-found))
    )
        (if (> home-score away-score)
            (begin
                (map-set teams home-team (merge home-data {wins: (+ (get wins home-data) u1)}))
                (map-set teams away-team (merge away-data {losses: (+ (get losses away-data) u1)}))
                (ok true)
            )
            (if (< home-score away-score)
                (begin
                    (map-set teams home-team (merge home-data {losses: (+ (get losses home-data) u1)}))
                    (map-set teams away-team (merge away-data {wins: (+ (get wins away-data) u1)}))
                    (ok true)
                )
                (begin
                    (map-set teams home-team (merge home-data {draws: (+ (get draws home-data) u1)}))
                    (map-set teams away-team (merge away-data {draws: (+ (get draws away-data) u1)}))
                    (ok true)
                )
            )
        )
    )
)

;; Read only functions
(define-read-only (get-team-info (team principal))
    (map-get? teams team)
)

(define-read-only (get-match (match-id uint))
    (map-get? matches match-id)
)
