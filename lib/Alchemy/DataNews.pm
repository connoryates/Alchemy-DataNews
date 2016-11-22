package Alchemy::DataNews;

use Furl;
use JSON::XS qw(decode_json);
use Carp qw(croak cluck);
use URI;
use Try::Tiny;

our $VERISON = '0.01';

use constant ALCHEMY_ENDPOINT => 'https://gateway-a.watsonplatform.net/calls/data/GetNews';

our %UNIT_MAP = (
    days    => 'd',
    seconds => 's',
    minutes => 'm',
    months  => 'M',
    years   => 'y',
);

sub new {
    my ($class, %data) = @_;

    croak "No API key!" unless defined $data{api_key};

    my $self = bless {
        _timeframe       => $data{timeframe}       || undef,
        _debug           => $data{debug}           || 0,
        _max_results     => $data{max_results}     || 5,
        _next_page       => $data{next_page}       || undef,
        _rank            => $data{rank}            || undef,
        _time_slice      => $data{time_slice}      || undef,
        _dedup           => $data{dedup}           || undef,
        _dedup_threshold => $data{dedup_threshold} || undef,
        _count           => $data{count}           || 10,
        _api_key         => $data{api_key},
        _keywords        => $data{keywords}        || undef,
        _return_fields   => $data{return_fields}   || undef,
        _taxonomy        => $data{taxonomy}        || undef,
        _entity          => $data{entity}          || undef,
        _relations       => $data{relations}       || undef,
        _sentiment       => $data{sentiment}       || undef,
    }, $class;

    return $self;
}

sub search_news {
    my ($self, $info) = @_;

    croak "Missing required arg : info" unless defined $info;
    croak "Arg info must be a HashRef"  unless ref($info) eq 'HASH';

    # Allow the user to specify [keywords, taxonomies] on construction
    # or on method call
    $self->{_keywords}  = $info->{keywords}  if defined $info->{keywords};
    $self->{_taxonomy}  = $info->{taxonomy}  if defined $info->{taxonomy};
    $self->{_entity}    = $info->{entity}    if defined $info->{entity};
    $self->{_relations} = $info->{relations} if defined $info->{relations};
    $self->{_sentiment} = $info->{sentiment} if defined $info->{sentiment};

    my $timeframe  = $info->{timeframe};
    my %query_form = %{ $self->_format_date_query($timeframe) || +{} };

    %query_form = (
        %query_form,
        %{ $self->_format_keyword_query }
    ) if $self->{_keywords};

    %query_form = (
        %query_form,
        %{ $self->_format_taxonomy_query }
    ) if $self->{_taxonomy};

    %query_form = (
        %query_form,
        %{ $self->_format_concepts_query }
    ) if $self->{_concept};

    %query_form = (
        %query_form,
        %{ $self->_format_entity_query }
    ) if $self->{_entity};

    %query_form = (
        %query_form,
        %{ $self->_format_relations_query }
    ) if $self->{_relations};

    %query_form = (
        %query_form,
        %{ $self->_format_sentiment_query }
    ) if $self->{_sentiment};

    my $search_query = $self->_search_query(\%query_form);

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
    my ($self, $timeframe) = @_;

    croak "Missing required param : timeframe"  unless defined $timeframe;
    croak "Arg timeframe must be a HashRef" unless ref($timeframe) eq 'HASH';

    my $start = $timeframe->{start};
    
    my $start_string;
    if ( defined $time->{end} ) {
        my $unit = $UNIT_MAP{ $start->{unit} };

        $start_string = $start->{date} . "-" . $start->{amount_before} . $unit;
    }
    else {
        $start_string = "now-2d";
    }

    my $date_query = {
        start => $start_string,
        end   => $timeframe->{end} || 'now',
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

    if (ref($keywords) and ref($keywords) eq 'ARRAY') {
        foreach my $keyword (@$keywords) {
            while (my ($type, $value) = each %$keyword) {
                my $query_string;

                if (ref($value) eq 'ARRAY') {
                    $search_string = join '^', @$value;
                }
                else {
                    $search_string = $v;
                }

                if ($type eq 'title') {
                    $query_string = 'q.enriched.url.title';
                    $params->{$query_string} = 'O[' . $search_string . ']';
                }
                elsif ($type eq 'text') {
                    $query_string = 'q.enriched.url.text';
                    $params->{$query_string} = 'O[' . $search_string . ']';
                }
            }
        }
    }
    elsif (ref($keywords) and ref($keywords) eq 'HASH') {
        while (my ($type, $value) = each %$keywords) {
            my $query_string;

            if (ref($value) eq 'ARRAY') {
                $search_string = join '^', @$value;
            }
            else {
                $search_string = $v;
            }

            if ($type eq 'title') {
                $query_string = 'q.enriched.url.title';
                $params->{$query_string} = 'O[' . $search_string . ']';
            }
            elsif ($type eq 'text') {
                $query_string = 'q.enriched.url.text';
                $params->{$query_string} = 'O[' . $search_string . ']';
            }
        }
    }
    else {
        $query_string = 'q.enriched.url.text';
        $params->{$query_string} = 'O[' . $search_string . ']';
    }

    return $params;
}

sub _format_taxonomy_query {
    my $self = shift;

    my $taxonomy = $self->{_taxonomy};

    my $params       = {};
    my $query_string = 'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label';

    if (ref($taxonomy) and ref($taxonomy) eq 'ARRAY') {
        my $search_string = join '^', @{ $taxonomy };
        $params->{$query_string} = 'O[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = 'O[' . $taxonomy . ']';
    }

    return $params;
}

sub _format_concepts_query {
    my $self = shift;

    my $concepts = $self->{_concepts};

    my $params       = {};
    my $query_string = 'q.enriched.url.concepts.concept.text';

    if (ref($concept) and ref($concept) eq 'ARRAY') {
        my $search_string = join '^', @{ $concept };
        $params->{$query_string} = 'O[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = 'O[' . $concept . ']';
    }

    return $params;
}

sub _format_entity_query {
    my $self   = shift;
    my $entity = $self->{_entity};

    my $params = {};

    my $type_query   = 'q.enriched.url.enrichedTitle.entities.entity.type';
    my $entity_query = 'q.enriched.url.enrichedTitle.entities.entity.text';

    while ( ($type, $value) = each %$entity ) {
        if (ref($value) and ref($value) eq 'ARRAY') {
            my $search_string = join '^', @{ $value };

            $params->{$type_query}   = $type;
            $params->{$entity_query} = $search_string;
        }
        else {
            $params->{$type_query}   = $type;
            $params->{$entity_query} = $value;
        }
    }

    return $params;
}

sub _format_relations_query {
    my $self = shift;

    my $relations = $self->{_relations};
    my $params    = {};

    my $query_string = 'q.enriched.url.enrichedTitle.relations.relation';

    my ($target, $action, $orig_target);
 
    if (ref($relations) and ref($relations) eq 'HASH') {
        while ( my ($key, $value) = each %$relations ) {
            if ($key eq 'target') {
                $target      = 'subject.entities.entity.type=' . $value;
                $orig_target = $value;
            }
            elsif ($key eq 'action') {
                if (ref($value) and ref($value) eq 'ARRAY') {
                    my $search_string = join '^', @$value;
 
                    $action = 'acton.verb.text=' . 'O[' . $search_string . ']';
                }
                else {
                    $action = 'acton.verb.text=' . $value
                }
            }
            else {
                cluck "Unknown key in relations argument. Skipping query format";
                return undef;
            }
        }

        my $rel_string  = '|' . $target . $action;
           $rel_string .= 'object.entities.entity.type=' . $orig_target . '|';

        return $rel_string;
    }
    else {
        croak "Unsupported data type for relations query";
    }

    return;
}

sub _format_sentiment_query {
    my $self = shift;

    my $sentiment = $self->{_sentiment};
    my $params    = {};

    my $query_string = 'q.enriched.url.enrichedTitle.docSentiment';

    if (ref($sentiment) and ref($sentiment) eq 'HASH') {
        my $sent_string = '|type=';
 
        if (my $type = $sentiment->{type}) {
            if (ref($type) and ref($type) eq 'ARRAY') {
                $sent_string .= O[' . join '^', @$value . '],';
            }
            else {
                $sent_string .= $type . ',';
            }
        }
        if (my $score = $sentiment->{score}) {
            if (ref $score and ref($score) eq 'HASH') {
                my $value    = $score->{value};
                my $operator = $score->{operator};

                unless ($operator =~ /(?:<|<=|>=|=)/) {
                    cluck "Invalid operator, cannot format sentiment query";
                    return undef;
                }

                $sent_string .= $value . $operator . '|';
            }
            else {
                cluck "Unsupported data structure in sentiment value, cannot build sentiment query";
                return undef;
            }
        }
        else {
            cluck "Unknown key in sentiment query";
        }

        $params->{$query_string} = $sent_string;
    }
    else {
        cluck "Unsupported data structure in sentiment value, cannot build sentiment query";
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
    
    return 'enriched.url.url,enriched.url.title';
}

1
;
