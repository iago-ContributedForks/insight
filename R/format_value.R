#' @title Numeric Values Formatting
#' @name format_value
#'
#' @description
#' `format_value()` converts numeric values into formatted string values2, where
#' formatting can be something like rounding digits, scientific notation etc.
#' `format_percent()` is a short-cut for `format_value(as_percent = TRUE)`.
#'
#' @param x Numeric value.
#' @param digits Number of digits for rounding or significant figures. May also
#'   be `"signif"` to return significant figures or `"scientific"`
#'   to return scientific notation. Control the number of digits by adding the
#'   value as suffix, e.g. `digits = "scientific4"` to have scientific
#'   notation with 4 decimal places, or `digits = "signif5"` for 5
#'   significant figures (see also [signif()]).
#' @param protect_integers Should integers be kept as integers (i.e., without
#'   decimals)?
#' @param missing Value by which `NA` values are replaced. By default, an
#'   empty string (i.e. `""`) is returned for `NA`.
#' @param width Minimum width of the returned string. If not `NULL` and
#'   `width` is larger than the string's length, leading whitespaces are
#'   added to the string.
#' @param as_percent Logical, if `TRUE`, value is formatted as percentage
#'   value.
#' @param zap_small Logical, if `TRUE`, small values are rounded after
#'   `digits` decimal places. If `FALSE`, values with more decimal
#'   places than `digits` are printed in scientific notation.
#' @param ... Arguments passed to or from other methods.
#'
#'
#' @return A formatted string.
#'
#' @examples
#' format_value(1.20)
#' format_value(1.2)
#' format_value(1.2012313)
#' format_value(c(0.0045, 234, -23))
#' format_value(c(0.0045, .12, .34))
#' format_value(c(0.0045, .12, .34), as_percent = TRUE)
#' format_value(c(0.0045, .12, .34), digits = "scientific")
#' format_value(c(0.0045, .12, .34), digits = "scientific2")
#'
#' # default
#' format_value(c(0.0045, .123, .345))
#' # significant figures
#' format_value(c(0.0045, .123, .345), digits = "signif")
#'
#' format_value(as.factor(c("A", "B", "A")))
#' format_value(iris$Species)
#'
#' format_value(3)
#' format_value(3, protect_integers = TRUE)
#'
#' format_value(head(iris))
#' @export
format_value <- function(x, ...) {
  UseMethod("format_value")
}


#' @rdname format_value
#' @export
format_value.data.frame <- function(x,
                                    digits = 2,
                                    protect_integers = FALSE,
                                    missing = "",
                                    width = NULL,
                                    as_percent = FALSE,
                                    zap_small = FALSE,
                                    ...) {
  as.data.frame(sapply(
    x,
    format_value,
    digits = digits,
    protect_integers = protect_integers,
    missing = missing,
    width = width,
    as_percent = as_percent,
    zap_small = zap_small,
    simplify = FALSE
  ))
}


#' @rdname format_value
#' @export
format_value.numeric <- function(x,
                                 digits = 2,
                                 protect_integers = FALSE,
                                 missing = "",
                                 width = NULL,
                                 as_percent = FALSE,
                                 zap_small = FALSE,
                                 ...) {
  if (protect_integers) {
    out <- .format_value_unless_integer(
      x,
      digits = digits,
      .missing = missing,
      .width = width,
      .as_percent = as_percent,
      .zap_small = zap_small,
      ...
    )
  } else {
    out <- .format_value(
      x,
      digits = digits,
      .missing = missing,
      .width = width,
      .as_percent = as_percent,
      .zap_small = zap_small,
      ...
    )
  }

  # Deal with negative zeros
  if (!is.factor(x)) {
    whitespace <- ifelse(is.null(width), "", " ")
    out[out == "-0"] <- paste0(whitespace, "0")
    out[out == "-0.0"] <- paste0(whitespace, "0.0")
    out[out == "-0.00"] <- paste0(whitespace, "0.00")
    out[out == "-0.000"] <- paste0(whitespace, "0.000")
    out[out == "-0.0000"] <- paste0(whitespace, "0.0000")
  }
  out
}

#' @export
format_value.double <- format_value.numeric

#' @export
format_value.character <- format_value.numeric

#' @export
format_value.factor <- format_value.numeric

#' @export
format_value.logical <- format_value.numeric



# shortcut

#' @rdname format_value
#' @export
format_percent <- function(x, ...) {
  format_value(x, ..., as_percent = TRUE)
}




.format_value_unless_integer <- function(x,
                                         digits = 2,
                                         .missing = "",
                                         .width = NULL,
                                         .as_percent = FALSE,
                                         .zap_small = FALSE, ...) {
  if (is.numeric(x) && !all(.is.int(stats::na.omit(x)))) {
    .format_value(
      x,
      digits = digits,
      .missing = .missing,
      .width = .width,
      .as_percent = .as_percent,
      .zap_small = .zap_small
    )
  } else if (anyNA(x)) {
    .convert_missing(x, .missing)
  } else if (is.numeric(x) && all(.is.int(stats::na.omit(x))) && !is.null(.width)) {
    format(x, justify = "right", width = .width)
  } else {
    as.character(x)
  }
}



.format_value <- function(x, digits = 2, .missing = "", .width = NULL, .as_percent = FALSE, .zap_small = FALSE, ...) {
  # proper character NA
  if (is.na(.missing)) .missing <- NA_character_

  if (is.numeric(x)) {
    if (isTRUE(.as_percent)) {
      need_sci <- (abs(100 * x) >= 1e+5 | (log10(abs(100 * x)) < -digits)) & x != 0
      if (.zap_small) {
        x <- ifelse(is.na(x), .missing, sprintf("%.*f%%", digits, 100 * x))
      } else {
        x <- ifelse(is.na(x), .missing,
          ifelse(need_sci,
            sprintf("%.*e%%", digits, 100 * x),
            sprintf("%.*f%%", digits, 100 * x)
          )
        )
      }
    } else {
      if (is.character(digits) && grepl("scientific", digits, fixed = TRUE)) {
        digits <- tryCatch(
          expr = {
            as.numeric(gsub("scientific", "", digits, fixed = TRUE))
          },
          error = function(e) {
            5
          }
        )
        if (is.na(digits)) digits <- 5
        x <- sprintf("%.*e", digits, x)
      } else if (is.character(digits) && grepl("signif", digits, fixed = TRUE)) {
        digits <- tryCatch(
          expr = {
            as.numeric(gsub("signif", "", digits, fixed = TRUE))
          },
          error = function(e) {
            NA
          }
        )
        if (is.na(digits)) digits <- 3
        x <- as.character(signif(x, digits))
      } else {
        need_sci <- (abs(x) >= 1e+5 | (log10(abs(x)) < -digits)) & x != 0
        if (.zap_small) {
          x <- ifelse(is.na(x), .missing, sprintf("%.*f", digits, x))
        } else {
          x <- ifelse(is.na(x), .missing,
            ifelse(need_sci,
              sprintf("%.*e", digits, x),
              sprintf("%.*f", digits, x)
            )
          )
        }
      }
    }
  } else if (anyNA(x)) {
    x <- .convert_missing(x, .missing)
  }

  if (!is.null(.width)) {
    x <- format(x, justify = "right", width = .width)
  }

  x
}


.convert_missing <- function(x, .missing) {
  if (is.na(.missing)) {
    .missing <- NA_character_
  } else {
    .missing <- as.character(.missing)
  }

  if (length(x) == 1) {
    return(.missing)
  }

  missings <- which(is.na(x))
  x[missings] <- .missing
  x[!missings] <- as.character(x)
  x
}


.is.int <- function(x) {
  tryCatch(
    expr = {
      ifelse(is.infinite(x), FALSE, x %% 1 == 0)
    },
    warning = function(w) {
      is.integer(x)
    },
    error = function(e) {
      FALSE
    }
  )
}


.is.fraction <- function(x) {
  !all(.is.int(x)) && is.numeric(x) && n_unique(x) > 2
}
