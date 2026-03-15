alias Portal.{Repo, Account, Actor, Site, Authentication}

mappings = case File.read("provision-uuids.json") do
  {:ok, content} ->
    case Jason.decode(content) do
      {:ok, mapping} -> mapping
      _ -> %{"accounts" => %{}}
    end
  _ -> %{"accounts" => %{}}
end

IO.puts("INFO: Fetching account")
account = case Repo.get_by(Account, slug: "main") do
  nil -> raise "Account 'main' not found"
  account -> account
end

# Build a subject for token creation
subject = %Authentication.Subject{
  account: account,
  actor: %Actor{id: Ecto.UUID.generate(), type: :account_admin_user},
  credential: %Authentication.Credential{type: :portal_session, id: Ecto.UUID.generate()},
  expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
  context: %Authentication.Context{type: :portal, remote_ip: {127, 0, 0, 1}, user_agent: "create-tokens"}
}

# Create gateway token
IO.puts("INFO: Creating gateway token")
site_id = get_in(mappings, ["accounts", "main", "sites", "site"])
site = Repo.get_by!(Site, account_id: account.id, id: site_id)
{:ok, gateway_token} = Authentication.create_gateway_token(site, subject)
gateway_encoded = Authentication.encode_fragment!(gateway_token)
IO.puts("Created gateway token: #{gateway_encoded}")
File.write!("gateway_token.txt", gateway_encoded)

# Create client token
IO.puts("INFO: Creating client token for service account")
actor_id = get_in(mappings, ["accounts", "main", "actors", "client"])
actor = Repo.get_by!(Actor, account_id: account.id, id: actor_id)
{:ok, client_token} = Authentication.create_headless_client_token(
  actor,
  %{expires_at: DateTime.utc_now() |> DateTime.add(365, :day)},
  subject
)
client_encoded = Authentication.encode_fragment!(client_token)
IO.puts("Created client token: #{client_encoded}")
File.write!("client_token.txt", client_encoded)
