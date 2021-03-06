# 
library(dplyr)
library(purrr)
library(rlang)
library(tibble)

parsemodel <- function(model){
  UseMethod("parsemodel")
}


parsemodel.default <- function(model){
  
  
  terms <- model$terms
  
  labels <- attr(terms, "term.labels")
  
  tidy <- tibble(labels)
  
  xl <- model$xlevels
  
  if(length(xl) > 0){
    xlevels <- names(xl) %>%
      map({~tibble(
        labels = .x,
        vals = as.character(xl[[.x]])) %>%
          rowid_to_column("row")}
      ) %>%
      bind_rows() %>%
      filter(row > 1) %>%
      select(-row)
    
    tidy <- tidy %>%
      left_join(xlevels, by = "labels") 
  }
  
  i <- attr(terms, "intercept")
  if(!is.null(i)){
    tidy <-
      tibble(
        labels = "(Intercept)",
        vals = ""
      ) %>%
      bind_rows(tidy) 
  }
  
  tidy <- tidy %>% 
    mutate(
      vals = ifelse(is.na(vals), "", vals),
      type = case_when(
        labels == "(Intercept)" ~ "intercept",
        vals == "" ~ "continuous",
        vals != "" ~ "categorical",
        TRUE ~ "error")
    ) %>%
    bind_rows(tibble(
      labels = c("sigma2", "residual", "offset", "model"), 
      vals = c(
        summary(model)$sigma^2,
        model$df.residual,
        as.character(model$call$offset),
        class(model)[[1]]
      ),
      type = "variable"
    ))
  
  
  
  coef <- summary(model)$coefficients  %>%
    as.data.frame() %>%
    rownames_to_column("coef_labels") %>%
    select(coef_labels, 
           estimate = Estimate) 
  
  res.var <- summary(model)$sigma^2
  
  qr <- qr.solve(qr.R(model$qr)) %>%
    as.data.frame() %>%
    rownames_to_column()
  
  colnames(qr) <- c("coef_labels", paste0("qr_", 1:nrow(qr)))
  
  tidy <- tidy %>%
    mutate(coef_labels = paste0(labels, vals)) %>%
    full_join(coef, by = "coef_labels") %>%
    full_join(qr, by = "coef_labels") %>%
    select(- coef_labels) %>%
    mutate(sym_labels = syms(labels))
  
  if(any(is.na(tidy$labels))){
    stop("Error parsing the model")
  }
  
  tidy
}