# --
# Copyright (C) 2022 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Admin::Ticket::DeleteMergedTickets;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::System::Ticket
    Kernel::System::LinkObject
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete merged tickets that have no tickets linked');

    $Self->AddOption(
        Name        => 'limit',
        Description => "Max. number of tickets deleted in one run",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );
    $Self->AddOption(
        Name        => 'list-only',
        Description => "Do not delete the tickets, but list them on the console",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Delete merged tickets...</yellow>\n");

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');

    my $Limit = $Self->GetOption('limit') || 10_000;

    # search for all merged tickets
    my %TicketIDs = $TicketObject->TicketSearch(
        States => ['merged'],
        UserID => 1,
    );

    my $ListOnly = $Self->GetOption('list-only');

    my $Counter = 0;

    TICKETID:
    for my $TicketID ( sort { $a cmp $b } keys %TicketIDs ) {
        my %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
            UserID   => 1,
        );

        next TICKETID if !%Ticket;

        next TICKETID if $Ticket{State} ne 'merged';

        my $Parents = $LinkObject->LinkList(
            Object    => 'Ticket',
            Key       => $TicketID,
            Object2   => 'Ticket',
            Type      => 'ParentChild',
            State     => 'Valid',
            Direction => 'Source',
            UserID    => 1,
        );

        next TICKETID if %{ $Parents || {} };

        $Self->Print("<yellow>$Ticket{TicketNumber} - $Ticket{Title}.</yellow>\n");
        last TICKETID if $Counter++ == $Limit;

        next TICKETID if $ListOnly;

        $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );
    }

    $Self->Print("<yellow>Handled $Counter tickets.</yellow>\n");

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
