#' Fieldbook experimental designs
#'
#' Function to deploy experimental designs
#'
#' @param data Experimental design data frame with the factors and level. See
#'   examples.
#' @param n_factors Number of factor in the experiment(default = 1). See
#'   details.
#' @param type Type of experimental arrange  (default = "crd"). See details.
#' @param rep  Number of replications in the experiment (default = 3).
#' @param serie Digits in the plot id (default = 2).
#' @param seed Replicability of draw results (default = 0) always random. See
#'   details.
#' @param qr Bar code prefix for data collection.
#'
#' @details The function allows to include the arguments in the sheet that have
#'   the information of the design. You should include 2 columns in the sheet:
#'   \code{{arguments}} and \code{{values}}. See examples. The information will
#'   be extracted automatically and deploy the design. \code{n_factors} = 1:
#'   crd, rcbd, lsd, lattice. \code{n_factors} = 2 (factorial): split_crd,
#'   split_rcbd \code{n_factors} >= 2 (factorial): crd, rcbd, lsd.
#'
#' @return A list with the fieldbook design
#'
#' @import dplyr
#' @importFrom purrr pluck as_vector
#' @importFrom stringr str_detect str_to_upper
#' @importFrom tibble tibble
#' @importFrom utils tail
#' @importFrom tidyr unite
#' @importFrom purrr discard
#' 
#' @export
#' 
#' @examples
#' 
#' \dontrun{
#'
#' library(inti)
#' library(gsheet)
#' 
#' url <- paste0("https://docs.google.com/spreadsheets/d/"
#'               , "1wXzDc6OFOFgDgjGiZX8qYB8hzvgspoPf-qUS5AsScus/edit#gid=1296863855")
#' # browseURL(url)
#' 
#' fb <- gsheet2tbl(url)
#' 
#' 
#' tarpuy_design(data = fb)
#' 
#' 
#' 
#' }

tarpuy_design <- function(data,
                             n_factors = 1,
                             type = "crd",
                             rep = 2,
                             serie = 2,
                             seed = 0,
                             qr = "fb"
                             ) {

  plots <- Row.names <- factors <- NULL
  
  if(FALSE) {
    
    data <- fb
    
    ncolum <- data %>% 
      as.data.frame() %>% 
      select(dplyr::contains("value")) %>% 
      pluck(1)[1] %>% 
      as.numeric()
    
    if(length(ncolum) == 0)
    
    
    treat_fcts <- data %>%
      select(!starts_with("{") | !ends_with("}")) %>% 
      select(1:{{ncolum}}) %>% 
      as.list() %>% 
      lapply(., function(x) unique(x)) %>% 
      map(discard, is.na) %>% 
      lengths() %>% 
      prod()
    
    
  }

# design type -------------------------------------------------------------
# -------------------------------------------------------------------------

type <- match.arg(type, c(
  "crd", "rcbd", "lsd", "lattice"
  , "split-crd", "split-rcbd"
  ))

# fix and clean data ------------------------------------------------------
# -------------------------------------------------------------------------

data_fb <- data %>%
  select(!starts_with("{") | !ends_with("}")) %>%
  select_if(~ !all(is.na(.))) %>%
  rename_with(~ gsub("\\s+|\\.", "_", .)) %>%
  mutate(across(everything(), ~ gsub(" ", "_", .))) %>%
  dplyr::tibble()

treatments_names <- data_fb %>% 
  names() 

treatments_levels <- data_fb %>%
  select( {{treatments_names}} ) %>%
  as.list() %>%
  lapply(., function(x) unique(x)) %>% 
  purrr::map(discard, is.na)

# extract arguments -------------------------------------------------------
# -------------------------------------------------------------------------

arguments <- data %>%
  select(starts_with("{") | ends_with("}")) %>%
  rename_with(~ gsub("\\{|\\}", "", .)) %>%
  drop_na()

col_arg <- c(
  "argument", "arguments", "argumento", "argumentos"
  , "parameter", "parameters", "parametro", "parametros"
  )

col_match <- names(arguments) %in% col_arg
col_name <- names(arguments)[col_match == TRUE]

if ( length(col_name)  > 0  )  {

  arguments_opt <- arguments %>%
    tibble::deframe()

} else { arguments_opt <- data.frame() }

# arguments values --------------------------------------------------------
# -------------------------------------------------------------------------

nfc_list <- c( "nFactor", "nFactors", "factors", "factor", "nfactors", "factores" )
nfc_match <- names(arguments_opt) %in% nfc_list
nfc_name <- names(arguments_opt)[nfc_match == TRUE]

if ( length(nfc_name)  > 0 ) {

  n_factors <- arguments_opt %>%
    pluck( nfc_name ) %>%
    as.numeric()

} else { n_factors }

# -------------------------------------------------------------------------

type_list <- c( "type", "design", "tipo" )
type_match <- names(arguments_opt) %in% type_list
type_name <- names(arguments_opt)[type_match == TRUE]

if ( length( type_name )  > 0 ) {

  type <- arguments_opt %>% pluck( type_name )

} else { type }

# -------------------------------------------------------------------------

rep_list <- c( "r", "rep", "replication", "replicates")
rep_match <- names(arguments_opt) %in% rep_list
rep_name <- names(arguments_opt)[rep_match == TRUE]

if ( length(rep_name)  > 0 ) {

  rep <- arguments_opt %>%
    pluck( rep_name ) %>%
    as.numeric()

} else { rep }

# -------------------------------------------------------------------------

serie_list <- c("serie", "series", "digits", "pdigits", "plotdigits")
serie_match <- names(arguments_opt) %in% serie_list
serie_name <- names(arguments_opt)[serie_match == TRUE]

if ( length(serie_name)  > 0 ) {

  serie <- arguments_opt %>%
    pluck("serie") %>%
    as.numeric()

} else { serie }

# -------------------------------------------------------------------------

seed_list <- c("seed", "Seed", "seeds", "semilla")
seed_match <- names(arguments_opt) %in% seed_list
seed_name <- names(arguments_opt)[seed_match == TRUE]

if ( length(seed_name)  > 0  ) {

  seed <- arguments_opt %>%
    pluck("seed") %>%
    as.numeric()

} else { seed }

# -------------------------------------------------------------------------

qr_list <- c("qr", "cod", "code", "qr-code")
qr_match <- names(arguments_opt) %in% qr_list
qr_name <- names(arguments_opt)[qr_match == TRUE]

if ( length(qr_name)  > 0  ) {
  
  qr <- arguments_opt %>%
    pluck("qr") %>%
    # iconv(., "latin1", "ASCII//TRANSLIT") %>% 
    stringi::stri_trans_general("Latin-ASCII") %>%
    stringr::str_to_upper() %>% 
    gsub("[[:space:]]", "-", .)
  
} else { 
  
  qr <- qr %>% 
    # iconv(., "latin1", "ASCII//TRANSLIT") %>% 
    stringi::stri_trans_general("Latin-ASCII") %>%
    stringr::str_to_upper() %>% 
    gsub("[[:space:]]", "-", .)
  
  }

# factor numbers ----------------------------------------------------------
# -------------------------------------------------------------------------

treat_name <- names(treatments_levels)[1:n_factors]
treat_fcts <- treatments_levels[treat_name]

# n_factor = 1 ------------------------------------------------------------
# -------------------------------------------------------------------------

          if (n_factors == 1) {
            
            onefact <- treat_fcts %>% pluck(1)
            
            if (type == "crd") {
              design <- agricolae::design.crd(
                trt = onefact,
                r = rep,
                serie = serie,
                seed = seed
              )

              result <- list(
                design = design %>%
                pluck("book") %>%
                dplyr::rename({{ treat_name }} := "onefact")
                )
            }

            if (type == "rcbd") {
              design <- agricolae::design.rcbd(
                trt = onefact,
                r = rep,
                serie = serie,
                seed = seed
              )

              result <- list(
                design = design %>%
                  pluck("book") %>%
                  dplyr::rename({{ treat_name }} := "onefact")
              )
            }

            if (type == "lsd") {

              design <- agricolae::design.lsd(
                trt = onefact,
                r = rep,
                serie = serie,
                seed = seed
              )
              result <- list(
                design = design %>%
                  pluck("book") %>%
                  dplyr::rename({{ treat_name }} := "onefact")
              )
            }

            if (type == "lattice") { # fix rename column?

              if( rep > 3 ) { rep <- 3 }

              design <- agricolae::design.lattice(
                trt = onefact,
                r = rep,
                serie = serie,
                seed = seed
              )

              result <- list(
                design = design %>%
                  pluck("book") %>%
                  dplyr::rename({{ treat_name }} := "trt")
              )

            }

          }

# n_factor >= 2 -----------------------------------------------------------
# -------------------------------------------------------------------------

        if( n_factors == 2 & startsWith(type, "split") ) {

# split-plot --------------------------------------------------------------
# -------------------------------------------------------------------------

          twofact_lvl <- treat_fcts[1:2]
          treat_name <- twofact_lvl %>% names()
          fact1 <- twofact_lvl %>% pluck(1)
          fact2 <- twofact_lvl %>% pluck(2)
          
          if (type == "split-crd") {

            design <- agricolae::design.split(
              trt1 = fact1,
              trt2 = fact2,
              r = rep,
              design = "crd",
              serie = serie,
              seed = seed
            )

            result <- list(
              design = design %>%
              pluck("book") %>%
              rename_with(~ {{ treat_name }}, tail(names(.), 2))
              )
          }

          if (type == "split-rcbd") {

            design <- agricolae::design.split(
              trt1 = fact1,
              trt2 = fact2,
              r = rep,
              design = "rcbd",
              serie = serie,
              seed = seed
            )

            result <- list(
              design = design %>%
              pluck("book") %>%
              rename_with(~ {{ treat_name }}, tail(names(.), 2))
              )
          }

        }

# factorial ---------------------------------------------------------------
# -------------------------------------------------------------------------

        if ( n_factors >= 2 && ( type == "crd" | type == "rcbd" | type == "lsd" ) ) {
          
          treat_lvls <- lengths(treat_fcts)

          design <- agricolae::design.ab(
            trt = treat_lvls,
            r = rep,
            serie = serie,
            design = type,
            seed = seed
          )

          # rename cols -------------------------------------------------------------
          # -------------------------------------------------------------------------

          col_rnm <- function(renamed_fb, treat, new_names) {

            oldn <- renamed_fb %>%
              dplyr::select({{treat}}) %>%
              unique() %>%
              as_vector()

            names <- structure(as.character(new_names),
                               names = as.character(oldn))

            renamed_fb %>%
              mutate(across({{treat}}, ~dplyr::recode(.x = ., !!!names))) %>%
              select({{treat}})
            
            }

          # -------------------------------------------------------------------------

          renamed_fb <- design %>%
            pluck("book") %>%
            rename_with(~ {{ treat_name }}, tail(names(.), n_factors))

          ini <- length(renamed_fb) - n_factors + 1
          fin <- length(renamed_fb)

          fb_recoded <- lapply(ini:fin, function(x) {
            
            colnm <- colnames(renamed_fb)[x]
            
            renamed_fb %>%
              col_rnm(renamed_fb = .,
                      treat = {{colnm}},
                      new_names = treat_fcts[[colnm]]
              )
            
            })

          result <- list(
            design = do.call(cbind, fb_recoded) %>%
            tibble() %>%
            merge(renamed_fb %>% select(!{{ treat_name }}),
                  .,
                  by = 0) %>%
            dplyr::arrange(plots) %>%
            select(!Row.names)
            )
        }

# include qr --------------------------------------------------------------
# -------------------------------------------------------------------------

result$design <- result$design %>% 
  unite(.
        , factors
        , c(names(.))
        , remove=FALSE
        , sep = "_"
        ) %>% 
  mutate(factors = paste(qr, factors, sep = "_")) %>% 
  rename('qr-code' = factors )

# result ------------------------------------------------------------------
# -------------------------------------------------------------------------

  return(result)

}

