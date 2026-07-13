package main

import (
	"log"
	"os"
	"path/filepath"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/jsvm"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
)

func main() {
	// Determine the default public directory path
	loosePublicDir := ""
	if exePath, err := os.Executable(); err == nil {
		loosePublicDir = filepath.Join(filepath.Dir(exePath), "pb_public")
	}

	app := pocketbase.New()

	// Register JSVM migrations and hooks support
	jsvm.MustRegister(app, jsvm.Config{
		HooksWatch: true,
	})

	// Register migration commands
	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		Automigrate: true, // auto-create migration files during dev
	})

	// Serve static files from the pb_public directory (if present)
	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		publicDir := loosePublicDir
		if publicDir == "" {
			publicDir = "./pb_public"
		}
		
		// check if publicDir exists
		if _, err := os.Stat(publicDir); err == nil {
			se.Router.GET("/{path...}", apis.Static(os.DirFS(publicDir), false))
		}
		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}
