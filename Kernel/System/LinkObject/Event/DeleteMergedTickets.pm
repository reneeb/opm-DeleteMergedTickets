# --
# Copyright (C) 2021 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::LinkObject::Event::DeleteMergedTickets;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
    Kernel::System::LinkObject
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LinkObject   = $Kernel::OM->Get('Kernel::System::LinkObject');

    # check needed stuff
    for my $Needed (qw(Data Event Config UserID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    for my $NeededData (qw(SourceObject SourceKey TargetObject TargetKey Type)) {
        if ( !$Param{Data}->{$NeededData} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededData in Data!",
            );

            return;
        }
    }

    my %Data = %{ $Param{Data} || {} };

    return 1 if $Data{Type}         ne 'ParentChild';
    return 1 if $Data{SourceObject} ne 'Ticket';
    return 1 if $Data{TargetObject} ne 'Ticket';

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Data{TargetKey},
        UserID   => $Param{UserID},
    );

    return 1 if !%Ticket;

    return 1 if $Ticket{State} ne 'merged';

    my $Parents = $LinkObject->LinkList(
        Object    => 'Ticket',
        Key       => $Data{TargetKey},
        Object2   => 'Ticket',
        Type      => 'ParentChild',
        State     => 'Valid',
        Direction => 'Source',
        UserID    => $Param{UserID},
    );

    return 1 if %{ $Parents || {} };

    $TicketObject->TicketDelete(
        TicketID => $Data{TargetKey},
        UserID   => $Param{UserID},
    );

    return 1;
}

1;
