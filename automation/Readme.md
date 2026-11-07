# Continuous Delivery Automation Framework (CDAF)

For principles and usage guidance see [https://cdaf.io](https://cdaf.io/10-cdaf/index.html).

For the complete set of samples and provisioning helpers, see [GitHub](https://github.com/cdaf/linux).

For related blog, see [LinkedIn articles](https://www.linkedin.com/in/jules-clements-842b589/recent-activity/articles/).

## Entry arguments

`entry.sh` accepts `BUILDNUMBER`, `BRANCH`, and `ACTION`, in that positional order.
`ci.sh` also accepts `LOCAL_WORK_DIR` and `REMOTE_WORK_DIR` as positions four and five.
Both accept case-insensitive named options with either `-` or `--`, and `-help` or
`--help` displays usage without starting a build or updating the build counter.

```bash
./entry.sh 42 main buildonly
./entry.sh -BUILDNUMBER 42 -BRANCH main -ACTION buildonly
./ci.sh 42 main --ACTION packageonly --LOCAL_WORK_DIR "local tasks"
```

Named and positional arguments can be mixed: positional values fill parameters
not supplied by name, in the order above. Use `--` to end option parsing.
`skipenv` remains exclusive to `cdEmulate.sh`.
