;; Define data storage
(define-map teams 
    principal 
    {name: (string-ascii 50), wins: uint, losses: uint, draws: uint, season-wins: uint, season-losses: uint, season-draws: uint}
)

(define-map matches 
    uint 
    {home-team: principal, away-team: principal, home-score: uint, away-score: uint, completed: bool, season-id: uint}
)

(define-map seasons
    uint
    {name: (string-ascii 50), start-time: uint, end-time: uint, active: bool}
)

(define-map tournaments
    uint
    {name: (string-ascii 50), teams: (list 16 principal), matches: (list 32 uint), winner: (optional principal), completed: bool, season-id: uint}
)

(define-data-var match-nonce uint u0)
(define-data-var season-nonce uint u0)
(define-data-var tournament-nonce uint u0)
(define-data-var current-season uint u0)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-team-exists (err u101))
(define-constant err-team-not-found (err u102))
(define-constant err-match-not-found (err u103))
(define-constant err-match-already-completed (err u104))
(define-constant err-season-not-found (err u105))
(define-constant err-tournament-not-found (err u106))
(define-constant err-tournament-full (err u107))

;; Season Management
(define-public (start-new-season (name (string-ascii 50)))
    (let ((season-id (var-get season-nonce)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set seasons season-id
                    {name: name,
                     start-time: block-height,
                     end-time: u0,
                     active: true}
                )
                (var-set season-nonce (+ season-id u1))
                (var-set current-season season-id)
                (ok season-id)
            )
            err-owner-only
        )
    )
)

(define-public (end-season (season-id uint))
    (let ((season (unwrap! (map-get? seasons season-id) err-season-not-found)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set seasons season-id
                    (merge season {end-time: block-height, active: false})
                )
                (ok true)
            )
            err-owner-only
        )
    )
)

;; Tournament Management  
(define-public (create-tournament (name (string-ascii 50)))
    (let ((tournament-id (var-get tournament-nonce)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set tournaments tournament-id
                    {name: name,
                     teams: (list ),
                     matches: (list ),
                     winner: none,
                     completed: false,
                     season-id: (var-get current-season)}
                )
                (var-set tournament-nonce (+ tournament-id u1))
                (ok tournament-id)
            )
            err-owner-only
        )
    )
)

(define-public (join-tournament (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments tournament-id) err-tournament-not-found))
          (team-data (unwrap! (get-team-info tx-sender) err-team-not-found)))
        (if (< (len (get teams tournament)) u16)
            (ok (map-set tournaments tournament-id
                (merge tournament
                    {teams: (unwrap! (as-max-len? (append (get teams tournament) tx-sender) u16) err-tournament-full)})))
            err-tournament-full)
    )
)

;; Original functions updated for seasons
(define-public (register-team (team-name (string-ascii 50)))
    (let ((team-data {name: team-name, 
                     wins: u0, 
                     losses: u0, 
                     draws: u0,
                     season-wins: u0,
                     season-losses: u0,
                     season-draws: u0}))
        (if (is-some (get-team-info tx-sender))
            err-team-exists
            (ok (map-set teams tx-sender team-data))
        )
    )
)

(define-public (schedule-match (home-team principal) (away-team principal))
    (let ((match-id (var-get match-nonce)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set matches match-id 
                    {home-team: home-team, 
                     away-team: away-team, 
                     home-score: u0, 
                     away-score: u0, 
                     completed: false,
                     season-id: (var-get current-season)}
                )
                (var-set match-nonce (+ match-id u1))
                (ok match-id)
            )
            err-owner-only
        )
    )
)

;; Updated to track season stats
(define-private (update-team-stats (home-team principal) (away-team principal) (home-score uint) (away-score uint))
    (let (
        (home-data (unwrap! (get-team-info home-team) err-team-not-found))
        (away-data (unwrap! (get-team-info away-team) err-team-not-found))
    )
        (if (> home-score away-score)
            (begin
                (map-set teams home-team (merge home-data {
                    wins: (+ (get wins home-data) u1),
                    season-wins: (+ (get season-wins home-data) u1)
                }))
                (map-set teams away-team (merge away-data {
                    losses: (+ (get losses away-data) u1),
                    season-losses: (+ (get season-losses away-data) u1)
                }))
                (ok true)
            )
            (if (< home-score away-score)
                (begin
                    (map-set teams home-team (merge home-data {
                        losses: (+ (get losses home-data) u1),
                        season-losses: (+ (get season-losses home-data) u1)
                    }))
                    (map-set teams away-team (merge away-data {
                        wins: (+ (get wins away-data) u1),
                        season-wins: (+ (get season-wins away-data) u1)
                    }))
                    (ok true)
                )
                (begin
                    (map-set teams home-team (merge home-data {
                        draws: (+ (get draws home-data) u1),
                        season-draws: (+ (get season-draws home-data) u1)
                    }))     
                    (map-set teams away-team (merge away-data {
                        draws: (+ (get draws away-data) u1),
                        season-draws: (+ (get season-draws away-data) u1)
                    }))
                    (ok true)
                )
            )
        )
    )
)

;; Additional read-only functions
(define-read-only (get-season-info (season-id uint))
    (map-get? seasons season-id)
)

(define-read-only (get-tournament-info (tournament-id uint))
    (map-get? tournaments tournament-id)
)

(define-read-only (get-current-season)
    (var-get current-season)
)
