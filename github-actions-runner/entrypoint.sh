#!/bin/sh -l

# download Github App private key
az config set auto-upgrade.enable=no
private_key="github_app_private_key.pem"
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
az storage blob download --account-name $AZURE_STORAGE -c $AZURE_STORAGE_CONTAINER -n $AZURE_STORAGE_BLOB -f $private_key
az logout

# get token from Github App
# https://zenn.dev/tmknom/articles/github-apps-token#%E3%81%8A%E3%82%8F%E3%82%8A%E3%81%AB
# 上記のスクリプトを参考にしました
base64url() {
  openssl enc -base64 -A | tr '+/' '-_' | tr -d '='
}

sign() {
  openssl dgst -binary -sha256 -sign "./$private_key"
}

header="$(printf '{"alg":"RS256","typ":"JWT"}' | base64url)"
now="$(date '+%s')"
iat="$((now - 60))"
exp="$((now + (3 * 60)))"
template='{"iss":"%s","iat":%s,"exp":%s}'
payload="$(printf "$template" "$GITHUB_APP_ID" "$iat" "$exp" | base64url)"
signature="$(printf '%s' "$header.$payload" | sign | base64url)"
jwt="$header.$payload.$signature"
rm ./$private_key

installation_id="$(curl --location --silent --request GET \
  --url "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/installation" \
  --header "Accept: application/vnd.github+json" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --header "Authorization: Bearer $jwt" \
  | jq -r '.id'
)"

token="$(curl --location --silent --request POST \
  --url "https://api.github.com/app/installations/$installation_id/access_tokens" \
  --header "Accept: application/vnd.github+json" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --header "Authorization: Bearer $jwt" \
  | jq -r '.token'
)"

# https://github.com/Azure-Samples/container-apps-ci-cd-runner-tutorial/blob/main/github-actions-runner/entrypoint.sh
# 上記のGithubのファイルを流用しています
registration_token="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $token" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runners/registration-token" \
  | jq -r '.token')"

./config.sh --url https://github.com/$GITHUB_OWNER/$GITHUB_REPO --token $registration_token --unattended --ephemeral && ./run.sh
