suppressMessages({
  .board <- board_ms365( # You should update this based on your permission to the data
    drive = Microsoft365R::get_business_onedrive("common"),
    path = "MorganStanley-QuantChallenge",
    versioned = FALSE
  )
})

.write <- function(..., name = NULL) {
  l <- list(...)
  if (is.null(name)) {
    name <- deparse(substitute({{ ... }})) |>
      head(-2) |>
      tail(-2) |>
      str_squish()
  }
  
  purrr::walk2(l, name, \(x, y) {
    pin_write(
      board = .board,
      name = y,
      x
    )
  })
}

.read <- function(...) {
  name <- deparse(substitute({{ ... }})) |>
    head(-2) |>
    tail(-2) |>
    str_squish()
  
  purrr::walk(name, \(x) {
    pin_read(
      board = .board,
      name = x
    ) |>
      assign(x = x, pos = 1)
  })
}