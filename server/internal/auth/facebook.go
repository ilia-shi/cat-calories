package auth

import "golang.org/x/oauth2"

var facebookEndpoint = oauth2.Endpoint{
	AuthURL:  "https://www.facebook.com/v19.0/dialog/oauth",
	TokenURL: "https://graph.facebook.com/v19.0/oauth/access_token",
}

func FacebookOAuthConfig(clientID, clientSecret, redirectURL string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Scopes:       []string{"email", "public_profile"},
		Endpoint:     facebookEndpoint,
	}
}
