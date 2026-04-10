# ECE0202-term-project

Term project for ECE 0202

# Contributing

Work in your own branch on the component you are assigned. Each component
should have an initialization procedure, and a run procedure. See
(main.s)[[src/main.s]] for the skelaton. Ideally changes to main should be
limited to procedure calls so we can easily test changes independently and
merge then when completed.

To import
```
;; Must import each procedure
IMPORT	MY_PROCEDURE_INIT ;; initialize relavant IO
IMPORT	MY_PROCEDURE_RUN      ;; dispatched by main, in main loop
```
