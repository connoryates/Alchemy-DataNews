package Alchemy::DataNews;

use Furl;
use JSON::XS qw(decode_json);
use Carp qw(croak cluck);
use URI;
use Try::Tiny;

our $VERISON = '0.00';

use constant ALCHEMY_ENDPOINT => 'https://gateway-a.watsonplatform.net/calls/data/GetNews';

sub new {
    my ($class, %data) = @_;

    croak "No API key!" unless defined $data{api_key};

    my $self = bless {
        _end             => $data{end}             || undef,
        _start           => $data{start}           || undef,
        _debug           => $data{debug}           || 0,
        _max_results     => $data{max_results}     || undef,
        _next_page       => $data{next_page}       || undef,
        _rank            => $data{rank}            || undef,
        _time_slice      => $data{time_slice}      || undef,
        _dedup           => $data{dedup}           || undef,
        _dedup_threshold => $data{dedup_threshold} || undef,
        _count           => $data{count}           || 10,
        _api_key         => $data{api_key},
        _keywords        => $data{keywords}        || undef,
        _return_fields   => $data{return_fields}   || undef,
    }, $class;

    return $self;
}

sub search_news {
    my ($self, $info) = @_;

    croak "Missing required arg : info" unless defined $info;
    croak "Arg info must be a HashRef" unless ref($info) eq 'HASH';

    # Allow the user to specify keywords on construction
    # or on method call
    $self->{_keywords} = $info->{keywords} if defined $info->{keywords};

    my $start_range  = "now-5h";
    my $end_date     = 'now';
#    my $start_range = defined $self->{_start}
#      ? $self->{_start}
#      : (defined $info->{start}
#        ? $info->{start}
#        : +{ begin => 'now', end => undef });

#    my $end_date = defined $self->{_end}
#      ? $self->{_end}
#      : (defined $info->{end}
#        ? $info->{end}
#        :  'now');


    my $query_form    = $self->_format_date_query($start_range, $end_date);
    my $keyword_form  = $self->_format_keyword_query;

    my %query_form    = (%$keyword_form, %$query_form);
    my $search_query  = $self->_search_query(\%query_form);

    my $content;
    try {
        my $resp = Furl->new->get($search_query);
        $content = decode_json( $resp->content );
    } catch {
        croak "Failed to get News Alert!\nReason : $_";
    };

    return $content;
}

sub _search_query {
    my ($self, $params) = @_;

    croak "Missing required arg : params" unless defined $params;
    croak "Arg params must be a HashRef" unless ref($params) eq 'HASH';

    $params->{api_key}        = $self->{_api_key};
    $params->{count}          = $self->{_count};
    $params->{outputMode}     = 'json';
    $params->{return}         = $self->_format_return_fields($self->{_return_fields});
    $params->{dedup}          = $self->{_dedup};
    $params->{next}           = $self->{_next_page};
    $params->{dedupThreshold} = $self->{_dedup_threshold};
    $params->{maxResults}     = $self->{_max_results};
    $params->{timeSlice}      = $self->{_time_slice};
    $params->{rank}           = $self->{_rank};

    delete $params->{$_} for grep { !defined $params->{$_} } (keys %$params);

    my $uri = URI->new(ALCHEMY_ENDPOINT);
       $uri->query_form($params);

    return $uri->as_string;
}

sub _format_date_query {
    my ($self, $start, $end) = @_;

#    croak "Missing required param : start" unless defined $start;
#    croak "Missing required param : end"   unless defined $end;
#    croak "Arg start must be a HashRef"    unless ref($start) eq 'HASH';
#
#    my $start_string;
#    if ( defined $start->{end} ) {
#        $start_string = $start->{begin} . "-" . $start->{end};
#    }
#    else {
#        $start_string = $start->{begin};
#    }
#
    my $date_query = {
        start => $start,
#        start => $start_string,
        end   => $end,
    };

    return $date_query;
}

sub _format_keyword_query {
    my $self = shift;

    my $keywords = $self->{_keywords};

    croak "Missing keywords, cannot format query" unless defined $keywords;

    croak "keywords must be an ArrayRef" unless ref($keywords)
      and ref($keywords) eq 'ARRAY';

    my $params = {};

    foreach my $keyword (@$keywords) {
        while( my ($k, $v) = each %$keyword ) {
            my ($query_string, $value_string);

            if (ref($v) eq 'ARRAY') {
                $search_string = join '^', @$v;                
            }
            else {
                $search_string = $v;
            }

            if ($k eq 'title') {
                $query_string = 'q.enriched.url.title';
                $params->{$query_string} = 'O[' . $search_string . ']';
            }
            elsif ($k eq 'text') {
                $query_string = 'q.enriched.url.text';
                $params->{$query_string} = 'O[' . $search_string . ']';
            }
        }
    }

    return $params;
}

sub _format_return_fields {
    my ($self, $fields) = @_;

    my $return_fields;

    if (defined $fields and ref($fields) and ref($fields) eq 'ARRAY') {
        my @fields;

        foreach my $field (@$fields) {
            if ($field eq 'title') {
                push @fields, 'enriched.url.title';
            }
            elsif ($field eq 'keywords') {
                push @fields, 'enriched.url.keywords';
            }
        }

        $return_fields = join ',', @fields;
    }
    else {
        $return_fields = 'enriched.url.keywords';
    }
    
    return $return_fields,
}

1;
