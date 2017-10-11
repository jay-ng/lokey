# senior-design
#### Parking Reminder and Analytics Mobile Application

## parking-app
Standard Xcode project with initial target of an iPhone


### Repo Overview
- master, “production branch”, everything is working
- develop, “beta branch”, everything should be working
- Branch from develop, feature / issue / user story


### Getting Started
Let’s get in to the habit of branching off develop for adding code. Once ready for merge, put in a pull request to develop. Develop will be merged periodically into master when we feel that it is stable or on an iteration bases.

Example workflow to add feature:
```
cd local/path/to/repo
git checkout develop
git pull
git checkout -b “a-new-branch-name”
```
Your local repo is now up to date with develop.. code away.
When you want to commit changes.. not necessarily done
```
git add *
git commit -m “a message about the commit”
git push
```

Now your remote branch is synced with your local changes. If you believe the branch is ready for develop. Navigate to develop in github and open a new pull request.

