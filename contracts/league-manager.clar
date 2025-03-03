;; Define data storage
(define-map teams 
    principal 
    {name: (string-ascii 50), wins: uint, losses: uint, draws: uint, season-wins: uint, season-losses: uint, season-draws: uint}
)

(define-map matches 
    uint 
    {home-team: principal, away-team: principal, home-score: uint, away-score: uint, completed: bool, season-id: uint, tournament-match: bool}
)

(define-map seasons
    uint
    {name: (string-ascii 50), start-time: uint, end-time: uint, active: bool, total-matches: uint}
)

(define-map tournaments
    uint
    {name: (string-ascii 50), 
     teams: (list 16 principal), 
     matches: (list 32 uint), 
     current-round: uint,
     winner: (optional principal), 
     completed: bool, 
     season-id: uint,
     bracket: (list 32 uint)}
)

;; Variables and Constants
(define-data-var match-nonce uint u0)
(define-data-var season-nonce uint u0)
(define-data-var tournament-nonce uint u0)
(define-data-var current-season uint u0)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-team-exists (err u101))
(define-constant err-team-not-found (err u102))
(define-constant err-match-not-found (err u103))
(define-constant err-match-already-completed (err u104))
(define-constant err-season-not-found (err u105))
(define-constant err-tournament-not-found (err u106))
(define-constant err-tournament-full (err u107))
(define-constant err-invalid-state (err u108))
(define-constant err-season-inactive (err u109))
(define-constant err-invalid-bracket-state (err u110))

;; Enhanced Season Management
(define-public (start-new-season (name (string-ascii 50)))
    (let ((season-id (var-get season-nonce)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set seasons season-id
                    {name: name,
                     start-time: block-height,
                     end-time: u0,
                     active: true,
                     total-matches: u0}
                )
                (var-set season-nonce (+ season-id u1))
                (var-set current-season season-id)
                (ok season-id)
            )
            err-owner-only
        )
    )
)

;; Enhanced Tournament Management with Bracket Support
(define-public (create-tournament (name (string-ascii 50)))
    (let ((tournament-id (var-get tournament-nonce))
          (current-season-id (var-get current-season)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (get-active-season)) err-season-inactive)
        (ok (begin
            (map-set tournaments tournament-id
                {name: name,
                 teams: (list ),
                 matches: (list ),
                 current-round: u0,
                 winner: none,
                 completed: false,
                 season-id: current-season-id,
                 bracket: (list )}
            )
            (var-set tournament-nonce (+ tournament-id u1))
            tournament-id
        ))
    )
)

;; New: Generate Tournament Bracket
(define-public (generate-tournament-bracket (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments tournament-id) err-tournament-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get completed tournament)) err-invalid-state)
        (asserts! (>= (len (get teams tournament)) u2) err-invalid-bracket-state)
        (ok (generate-bracket tournament-id))
    )
)

;; New: Calculate Season Statistics
(define-read-only (get-season-statistics (season-id uint))
    (let ((season (unwrap! (map-get? seasons season-id) err-season-not-found)))
        (ok {
            total-matches: (get total-matches season),
            active: (get active season),
            start-time: (get start-time season)
        })
    )
)

;; Private helper for bracket generation
(define-private (generate-bracket (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments tournament-id) err-tournament-not-found)))
        (map-set tournaments tournament-id
            (merge tournament
                {bracket: (create-initial-bracket (get teams tournament))})
        )
    )
)

;; [Rest of the original contract functions remain unchanged]
