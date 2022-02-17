# `bridge_ex` - Roadmap

This document describes the current status and the upcoming milestones of the `bridge_ex` library.

| Status | Goal | Breaking |
| :---: | :--- | :---: |
| ✔️ | Add a CHANGELOG | - |
| ✔️ | Add a ROADMAP for future developments | - |
| ❌ | [Support all possible outcomes of a GraphQL query](#support-all-possible-outcomes-of-a-graphql-query) | 💣 |
| ❌ | [Log queries safely](#log-queries-safely) | - |
| ❌ | [Use strings instead of atoms when deserializing GraphQL response](#use-strings-instead-of-atoms-when-deserializing-graphql-response) | 💣 |

## Support all possible outcomes of a GraphQL query

A GraphQL query may return

- only `data` on success
- only `errors` with null `data` on error
- both `data` and `errors` on partial success/failure

Right now `bridge_ex` returns

- `{:ok, data}` if `errors` is present
- `{:error, errors}` if `errors` is present, regardless of whether `data` is null or not

In the future, we may want to support the case of partial response, probably just by returning the whole response and letting the caller deal with its contents.

## Log queries safely

If `log_query_on_error` option is enabled, both the query and its variables are logged, thus possibly leaking private data. In the future, we could remove the `variables` portion, allowing the caller to log the query even in `staging` or `production` without any risk.

## Use strings instead of atoms when deserializing GraphQL response

When deserializing the GraphQL response we convert all keys to atoms. While nothing bad has happened yet, this may lead to problems: atoms are not garbage collected and there is a limit to how many atoms one can have. In general, generating atoms dynamically is not a good practice, especially based on external input.

The change should be easy, just change the [following function](lib/graphql/utils.ex)

```elixir
def decode_http_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}, _, _) do
 Jason.decode(body_string, keys: :atoms)
end
```

to convert keys to strings.
