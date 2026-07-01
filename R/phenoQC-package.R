#' @keywords internal
"_PACKAGE"

#' @importFrom rlang .data %||% abort inform warn sym := .env
#' @importFrom tibble tibble as_tibble
#' @importFrom dplyr bind_rows mutate select filter summarise group_by ungroup
#'   arrange n distinct pull across left_join rename any_of all_of if_else
#'   row_number between count
#' @importFrom tidyr pivot_wider pivot_longer drop_na
#' @importFrom tidyselect where
#' @importFrom purrr map map_dfr map_chr map_lgl map_dbl compact set_names
#' @importFrom glue glue
#' @importFrom cli cli_h1 cli_h2 cli_h3 cli_ul cli_alert_success
#'   cli_alert_info cli_alert_warning cli_alert_danger cli_abort
#'   cli_progress_bar cli_progress_update cli_progress_done
#' @importFrom ggplot2 ggplot aes geom_tile geom_point geom_boxplot
#'   geom_histogram geom_density geom_hline geom_vline geom_text geom_col
#'   scale_fill_viridis_c scale_colour_manual scale_fill_manual labs
#'   theme_minimal theme facet_wrap coord_fixed coord_flip element_text
#'   element_blank guide_colourbar ggtitle
#' @importFrom stats median sd quantile mad loess predict lm
#'   residuals complete.cases dist cor na.omit IQR as.formula var
#' @importFrom utils head
NULL
