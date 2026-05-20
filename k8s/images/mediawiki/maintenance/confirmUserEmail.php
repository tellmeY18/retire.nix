<?php
/**
 * Manually confirm a user's email address (admin tool).
 *
 * Usage: php maintenance/run.php confirmUserEmail <username>
 *
 * Use when confirmation emails end up in spam and admin needs to
 * verify the user manually.
 */

require_once __DIR__ . '/Maintenance.php';

class ConfirmUserEmail extends Maintenance {
    public function __construct() {
        parent::__construct();
        $this->addDescription( 'Manually confirm a user\'s email address' );
        $this->addArg( 'username', 'Username to confirm email for' );
    }

    public function execute() {
        $username = $this->getArg( 0 );
        $user = $this->getServiceContainer()->getUserFactory()->newFromName( $username );

        if ( !$user || $user->getId() === 0 ) {
            $this->fatalError( "User '$username' not found.\n" );
        }

        $email = $user->getEmail();
        if ( !$email ) {
            $this->fatalError( "User '$username' has no email set.\n" );
        }

        if ( $user->isEmailConfirmed() ) {
            $this->output( "User '$username' ($email) is already confirmed.\n" );
            return;
        }

        $user->confirmEmail();
        $user->saveSettings();
        $this->output( "✅ Email confirmed for '$username' ($email)\n" );
    }
}

$maintClass = ConfirmUserEmail::class;
require_once RUN_MAINTENANCE_IF_MAIN;
