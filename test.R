
source("model.R")
source("parsemodel.R")
source("intervals.R")


df <- mtcars %>%
  mutate(cyl = paste0("cyl", cyl))

m1 <- lm(mpg ~ wt + am, weights = cyl, data = mtcars)
m2 <- lm(mpg ~ wt + am, data = mtcars)
m3 <- lm(mpg ~ wt + am, offset = cyl, data = mtcars)
m4 <- lm(mpg ~ wt + cyl, data = df)
m5 <- glm(am ~ wt + mpg, data = mtcars)
m6 <- glm(am ~ cyl + mpg, data = df)


a1 <- as.numeric(predict(m1, mtcars))
a2 <- as.numeric(predict(m2, mtcars))
a3 <- as.numeric(predict(m3, mtcars))
a4 <- as.numeric(predict(m4, df))
a5 <- as.numeric(predict(m5, df))
a6 <- as.numeric(predict(m6, df))


b1 <- prediction_to_column(mtcars, m1) %>% pull()
b2 <- prediction_to_column(mtcars, m2) %>% pull()
b3 <- prediction_to_column(mtcars, m3) %>% pull()
b4 <- prediction_to_column(df, m4) %>% pull()
b5 <- prediction_to_column(df, m5) %>% pull()
b6 <- prediction_to_column(df, m6) %>% pull()



sum(a1 - b1 > 0.0000000000001)
sum(a2 - b2 > 0.0000000000001)
sum(a3 - b3 > 0.0000000000001)
sum(a4 - b4 > 0.0000000000001)
sum(a6 - b6 > 0.0000000000001) 

model <- m4


df <- mtcars %>%
  mutate(cyl = paste0("cyl", cyl))

head(df) %>%
  mutate(fit = !!score(model),
         interval = !!prediction_interval(model, 0.95)) %>%
  mutate(lwr = fit - interval,
         upr = fit + interval) %>%
  select(fit, lwr, upr)


head(df) %>%
  predict(model, ., interval = "prediction")