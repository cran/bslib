#' Sidebar layouts
#'
#' @description `r lifecycle::badge("experimental")`
#'
#' Sidebar layouts place UI elements, like input controls or additional context,
#' next to the main content area which often holds output elements like plots or
#' tables.
#'
#' There are several page, navigation, and layout functions that allow you to
#' create a sidebar layout. In each case, you can create a collapsing sidebar
#' layout by providing a `sidebar()` object to the `sidebar` argument the
#' following functions.
#'
#' * [page_sidebar()] creates a "page-level" sidebar.
#' * [page_navbar()] creates a multi-panel app with an (optional, page-level)
#'   sidebar that is shown on every panel.
#' * `layout_sidebar()` creates a "floating" sidebar layout component which can
#'   be used inside any [page()] and/or [card()] context.
#' * [navset_card_tab()] and [navset_card_pill()] create multi-tab cards with a
#'   shared sidebar that is accessible from every panel.
#'
#' See [the Sidebars article](https://rstudio.github.io/bslib/articles/sidebars.html)
#' on the bslib website to learn more.
#'
#' @references Sidebar layouts are featured in a number of pages on the bslib
#'   website:
#'
#'   * [Sidebars](https://rstudio.github.io/bslib/articles/sidebars.html)
#'   * [Cards: Sidebars](https://rstudio.github.io/bslib/articles/cards/index.html#sidebars)
#'   * [Getting Started: Dashboards](https://rstudio.github.io/bslib/articles/dashboards/index.html)
#'
#' @param ... Unnamed arguments can be any valid child of an [htmltools
#'   tag][htmltools::tags] and named arguments become HTML attributes on
#'   returned UI element. In the case of `layout_sidebar()`, these arguments are
#'   passed to the main content tag (not the sidebar+main content container).
#' @param width A valid [CSS unit][htmltools::validateCssUnit] used for the
#'   width of the sidebar.
#' @param position Where the sidebar should appear relative to the main content.
#' @param open The initial state of the sidebar, choosing from the following
#'   options:
#'
#'   * `"desktop"`: The sidebar starts open on desktop screen, closed on mobile.
#'     This is default sidebar behavior.
#'   * `"open"` or `TRUE`: The sidebar starts open.
#'   * `"closed"` or `FALSE`: The sidebar starts closed.
#'   * `"always"` or `NA`: The sidebar is always open and cannot be closed.
#'
#'   In `sidebar_toggle()`, `open` indicates the desired state of the sidebar,
#'   where the default of `open = NULL` will cause the sidebar to be toggled
#'   open if closed or vice versa. Note that `sidebar_toggle()` can only open or
#'   close the sidebar, so it does not support the `"desktop"` and `"always"`
#'   options.
#' @param id A character string. Required if wanting to re-actively read (or
#'   update) the `collapsible` state in a Shiny app.
#' @param title A character title to be used as the sidebar title, which will be
#'   wrapped in a `<header>` element with class `sidebar-title`. You can also
#'   provide a custom [htmltools::tag()] for the title element, in which case
#'   you'll likely want to give this element `class = "sidebar-title"`.
#' @param bg,fg A background or foreground color. If only one of either is
#'   provided, an accessible contrasting color is provided for the opposite
#'   color, e.g. setting `bg` chooses an appropriate `fg` color.
#' @param class CSS classes for the sidebar container element, in addition to
#'   the fixed `.sidebar` class.
#' @param max_height_mobile A [CSS length unit][htmltools::validateCssUnit()]
#'   defining the maximum height of the horizontal sidebar when viewed on mobile
#'   devices. Only applies to always-open sidebars that use `open = "always"`,
#'   where by default the sidebar container is placed below the main content
#'   container on mobile devices.
#' @param gap A [CSS length unit][htmltools::validateCssUnit()] defining the
#'   vertical `gap` (i.e., spacing) between adjacent elements provided to `...`.
#' @param padding Padding within the sidebar itself. This can be a numeric
#'   vector (which will be interpreted as pixels) or a character vector with
#'   valid CSS lengths. `padding` may be one to four values. If one, then
#'   that value will be used for all four sides. If two, then the first value
#'   will be used for the top and bottom, while the second value will be used
#'   for left and right. If three, then the first will be used for top, the
#'   second will be left and right, and the third will be bottom. If four, then
#'   the values will be interpreted as top, right, bottom, and left
#'   respectively.
#'
#' @export
sidebar <- function(
  ...,
  width = 250,
  position = c("left", "right"),
  open = c("desktop", "open", "closed", "always"),
  id = NULL,
  title = NULL,
  bg = NULL,
  fg = NULL,
  class = NULL,
  max_height_mobile = NULL,
  gap = NULL,
  padding = NULL
) {
  if (isTRUE(open)) {
    open <- "open"
  } else if (identical(open, FALSE)) {
    open <- "closed"
  } else if (isTRUE(is.na(open))) {
    open <- "always"
  }

  open <- rlang::arg_match(open)

  if (!is.null(max_height_mobile) && open != "always") {
    rlang::warn(
      'The `max_height_mobile` argument only applies to the sidebar when `open = "always"`.'
    )
    max_height_mobile <- NULL
  }

  if (!is.null(id)) {
    if (length(id) != 1 || is.na(id) || !nzchar(id)) {
      rlang::abort("`id` must be a non-empty, length-1 character string or `NULL`.")
    }

    # create input binding when id is provided by adding input class
    class <- c("bslib-sidebar-input", class)
  }

  if (is.null(id) && open != "always") {
    # always provide id when collapsible for accessibility reasons
    id <- paste0("bslib-sidebar-", p_randomInt(1000, 10000))
  }

  if (is.null(fg) && !is.null(bg)) {
    fg <- get_color_contrast(bg)
  }
  if (is.null(bg) && !is.null(fg)) {
    bg <- get_color_contrast(fg)
  }

  if (rlang::is_bare_character(title) || rlang::is_bare_numeric(title)) {
    title <- tags$header(title, class = "sidebar-title")
  }

  collapse_tag <-
    if (open != "always") {
      tags$button(
        class = "collapse-toggle",
        type = "button",
        title = "Toggle sidebar",
        "aria-expanded" = if (open %in% c("open", "desktop")) "true" else "false",
        "aria-controls" = id,
        collapse_icon()
      )
    }

  res <- list2(
    tag = tags$aside(
      id = id,
      class = c("sidebar", class),
      hidden = if (open %in% c("closed", "desktop")) NA,
      tags$div(
        class = "sidebar-content bslib-gap-spacing",
        title,
        style = css(
          gap = validateCssUnit(gap),
          padding = validateCssPadding(padding)
        ),
        ...
      )
    ),
    collapse_tag = collapse_tag,
    position = match.arg(position),
    open = open,
    width = validateCssUnit(width),
    max_height_mobile = validateCssUnit(max_height_mobile),
    color = list(bg = bg, fg = fg)
  )

  class(res) <- c("sidebar", class(res))
  res
}

#' @rdname sidebar
#' @param sidebar A [sidebar()] object.
#' @param fillable Whether or not the `main` content area should be considered a
#'   fillable (i.e., flexbox) container.
#' @param fill Whether or not to allow the layout container to grow/shrink to fit a
#'   fillable container with an opinionated height (e.g., `page_fillable()`).
#' @param border Whether or not to add a border.
#' @param border_radius Whether or not to add a border radius.
#' @param border_color The border color that is applied to the entire layout (if
#'   `border = TRUE`) and the color of the border between the sidebar and the
#'   main content area.
#' @inheritParams card
#' @inheritParams page_fillable
#'
#' @export
layout_sidebar <- function(
  ...,
  sidebar = NULL,
  fillable = TRUE,
  fill = TRUE,
  bg = NULL,
  fg = NULL,
  border = NULL,
  border_radius = NULL,
  border_color = NULL,
  padding = NULL,
  gap = NULL,
  height = NULL
) {

  if (!inherits(sidebar, "sidebar")) {
    sidebar <- sidebar(sidebar)
  }

  if (!(is.null(border) || isTRUE(border) || isFALSE(border))) {
    abort("`border` must be `NULL`, `TRUE`, or `FALSE`")
  }
  if (!(is.null(border_radius) || isTRUE(border_radius) || isFALSE(border_radius))) {
    abort("`border_radius` must be `NULL`, `TRUE`, or `FALSE`")
  }

  # main content area colors, if not provided ----
  if (is.null(fg) && !is.null(bg)) {
    fg <- get_color_contrast(bg)
  }
  if (is.null(bg) && !is.null(fg)) {
    bg <- get_color_contrast(fg)
  }

  main <- div(
    class = "main",
    class = if (fillable) "bslib-gap-spacing",
    style = css(
      padding = validateCssPadding(padding),
      gap = validateCssUnit(gap)
    ),
    ...
  )

  main <- bindFillRole(main, container = fillable)

  contents <- list(main, sidebar$tag, sidebar$collapse_tag)

  right <- identical(sidebar$position, "right")

  max_height_mobile <- sidebar$max_height_mobile %||%
    if (is.null(height)) "250px" else "50%"

  res <- div(
    class = "bslib-sidebar-layout bslib-mb-spacing",
    class = if (right) "sidebar-right",
    class = if (identical(sidebar$open, "closed")) "sidebar-collapsed",
    `data-bslib-sidebar-init` = TRUE,
    `data-bslib-sidebar-open` = sidebar$open,
    `data-bslib-sidebar-border` = if (!is.null(border)) tolower(border),
    `data-bslib-sidebar-border-radius` = if (!is.null(border_radius)) tolower(border_radius),
    style = css(
      "--_sidebar-width" = sidebar$width,
      "--_sidebar-bg" = sidebar$color$bg,
      "--_sidebar-fg" = sidebar$color$fg,
      "--_main-fg" = fg,
      "--_main-bg" = bg,
      "--bs-card-border-color" = border_color,
      height = validateCssUnit(height),
      "--_mobile-max-height" = max_height_mobile
    ),
    !!!contents,
    sidebar_init_js(),
    component_dependencies()
  )

  res <- bindFillRole(res, item = fill)

  res <- as.card_item(res)

  as_fragment(
    tag_require(res, version = 5, caller = "layout_sidebar()")
  )
}

#' @describeIn sidebar Toggle a `sidebar()` state during an active Shiny user
#'   session.
#' @param session A Shiny session object (the default should almost always be
#'   used).
#' @export
toggle_sidebar <- function(id, open = NULL, session = get_current_session()) {
  method <-
    if (is.null(open) || identical(open, "toggle")) {
      "toggle"
    } else if (isTRUE(open) || identical(open, "open")) {
      "open"
    } else if (isFALSE(open) || identical(open, "closed")) {
      "close"
    } else if (isTRUE(is.na(open)) || identical(open, "always")) {
      abort('`open = "always"` is not supported by `sidebar_toggle()`.')
    } else if (identical(open, "desktop")) {
      abort('`open = "desktop"` is not supported by `sidebar_toggle()`.')
    } else {
      abort('`open` must be `NULL`, `TRUE` (or "open"), or `FALSE` (or "closed").')
    }

  force(id)
  callback <- function() {
    session$sendInputMessage(id, list(method = method))
  }
  session$onFlush(callback, once = TRUE)
}

#' @rdname sidebar
#' @usage NULL
#' @export
sidebar_toggle <- toggle_sidebar

collapse_icon <- function() {
  if (!is_installed("bsicons")) {
    icon <- "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 16 16\" class=\"bi bi-chevron-left collapse-icon\" style=\"fill:currentColor;\" aria-hidden=\"true\" role=\"img\" ><path fill-rule=\"evenodd\" d=\"M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z\"></path></svg>"
    return(HTML(icon))
  }
  bsicons::bs_icon("chevron-left", class = "collapse-icon", size = NULL)
}

sidebar_init_js <- function() {
  # Note: if we want to avoid inline `<script>` tags in the future for
  # initialization code, we might be able to do so by turning the sidebar layout
  # container into a web component
  tags$script(
    `data-bslib-sidebar-init` = NA,
    HTML("bslib.Sidebar.initCollapsibleAll()")
  )
}
