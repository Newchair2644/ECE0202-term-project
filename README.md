# ECE0202-term-project
Term project for ECE 0202

# Contributing
Work in your own branch on the component/task you are assigned. Each component
should have an initialization procedure, and a run procedure. See
[main.s](src/main.s) general format. Ideally changes to main should be
limited to procedure calls so we can easily test changes independently and
merge them when completed.

# Git Workflow

## Setup (do this once)
Clone the repo and make sure you have the latest main:
```
git clone <repo_url>
cd ECE0202-term-project
git checkout main
git pull
```

## Creating your branch
```
git branch <your_branch_name>    # Create the branch
git checkout <your_branch_name>  # Switch to the branch
```

Or combined:

```
git checkout -b <your_branch_name>
```

## Saving and pushing your work

No vscode so you have to use git directly. (or git gui if you prefer)
```
git add <your_file>.s
git commit -m "brief description of what you did"
git push origin <your_branch_name>
```

## Merging into main
Before merging, pull the latest main into your branch first in case of conflicts:

```
git checkout main
git pull # pulls newest main into local main branch
git checkout <your_branch_name>
git merge main                   # Resolve any conflicts here, we merge main's changes into our branch
```

We are simply updating the branch to have the latest changes from main, THEN
merge from branch to main. To merge into main, you can either push your changes, github will see them and prompt you
to create a pull request, or you can merge them in the cli with `git merge`. Pull requests are preferred.

## Checking status

```
git status                       # See what files have changed
git log                          # See recent commits
git branch                       # See all branches, current marked with *
```

# Assembly Conventions

Every module file should include the constant headers at the top:

```
INCLUDE core_cm4_constants.s
INCLUDE stm32l476xx_constants.s
```

To import procedures from another module, each must be listed by name (i.e. add this to the [main.s](./src/main.s):

```
IMPORT  MY_PROCEDURE_INIT   ;; initialize relevant IO
IMPORT  MY_PROCEDURE_RUN    ;; dispatched by main loop
```

Each module must export its own procedures so main can import them:

```
EXPORT  MY_PROCEDURE_INIT
EXPORT  MY_PROCEDURE_RUN
```
