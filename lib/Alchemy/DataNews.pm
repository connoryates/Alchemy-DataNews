package Alchemy::DataNews;

use Furl;
use JSON::XS qw(decode_json);
use Carp qw(croak cluck);
use URI;
use Try::Tiny;

our $VERISON = '0.01';

use constant ALCHEMY_ENDPOINT => 'https://gateway-a.watsonplatform.net/calls/data/GetNews';

our $LAST_QUERY = '';
our $NEXT       = '';

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
        _exact_match     => $data{exact_math}      || undef,
        _join            => $data{join}            || undef,
    }, $class;

    return $self;
}

sub search_news {
    my ($self, $info) = @_;

    croak "Missing required arg : info" unless defined $info;
    croak "Arg info must be a HashRef"  unless ref($info) eq 'HASH';

    # Allow the user to specify query methods on construction
    # or on method call
    $self->{_keywords}  = $info->{keywords}  if defined $info->{keywords};
    $self->{_taxonomy}  = $info->{taxonomy}  if defined $info->{taxonomy};
    $self->{_entity}    = $info->{entity}    if defined $info->{entity};
    $self->{_relations} = $info->{relations} if defined $info->{relations};
    $self->{_sentiment} = $info->{sentiment} if defined $info->{sentiment};
    $self->{_timeframe} = $info->{timeframe} if defined $info->{timeframe};

    # Query attributes
    $self->{_exact_match} = $info->{exact_match} if defined $info->{exact_match};
    $self->{_join}        = $info->{join}        if defined $info->{join};

    my %query_form   = %{ $self->_format_date_query || +{} };
    my $formatted    = $self->_format_form(\%query_form);
    my $search_query = $self->_search_news($formatted);

    $LAST_QUERY = $search_query;

    return $self->_fetch_query($search_query);
}

sub next {
    my $self  = shift;
    my $query = shift || $LAST_QUERY;
    my $next  = shift || $NEXT;

    my $uri = URI->new($query);
       $uri->query_form( next => $next );

    return $self->_fetch_query($uri->as_string);   
}

sub _fetch_query {
    my ($self, $query) = @_;

    my $content;
    try {
        my $resp = Furl->new->get($query);
        $content = decode_json( $resp->content );
    } catch {
        croak "Failed to get News Alert!\nReason : $_";
    };

    # No next field if you want raw output!
    if (defined $content and ref($content) and ref($content) eq 'HASH') {
        $NEXT = $content->{result}->{next} || '';
    }

    return $content;
}

sub _format_queries {
    my ($self, $query_form) = @_;

    my @query_types = qw(
        _keyword
        _taxonomy
        _concepts
        _entity
        _relations
        _sentiment
    );

    my %query_form = %$query_form;

    foreach my $query_type (@query_types) {
        next unless defined $self->{$query_type};

        my $method = '_format' . $query_type . '_query';

        if ($self->can($method)) {
            %query_form = ( %query_form, %{ $self->$method } );
        }
    }

    return \%query_form; 
}

sub _search_news {
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
    my $self = shift;

    my $timeframe = $self->{_timeframe};

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

    my $params = {};

    if (ref($keywords) and ref($keywords) eq 'ARRAY') {
        foreach my $keyword (@$keywords) {
            if (ref($keyword) and ref($keyword) eq 'HASH') {

                my $prefix;
                if (defined $keyword->{join}) {
                    # Allow custom joins
                    $prefix = $self->__get_prefix($keyword->{join});
                }

                $prefix ||= $self->__get_prefix;

                while (my ($type, $value) = each %$keyword) {
                    my $query_string;

                    if (ref($value) eq 'ARRAY') {
                        my $search_string = join '^', @$value;

                        if ($type eq 'title') {
                            $query_string = 'q.enriched.url.title';
                            $params->{$query_string} = $prefix . '[' . $search_string . ']';
                        }
                        elsif ($type eq 'text') {
                            $query_string = 'q.enriched.url.text';
                            $params->{$query_string} = $prefix . '[' . $search_string . ']';
                        }
                    }
                    else {
                        if ($type eq 'title') {
                            $query_string = 'q.enriched.url.title';
                            $params->{$query_string} = $value;
                        }
                        elsif ($type eq 'text') {
                            $query_string = 'q.enriched.url.text';
                            $params->{$query_string} = $value;
                        }
                    }
                }
            }
            else {
                my $query_string  = 'q.enriched.url.text';
                my $search_string = join '^', @$keywords;

                my $prefix = $self->__get_prefix;

                $params->{$query_string} = $prefix . '[' . $search_string . ']';
            }
        }
    }
    elsif (ref($keywords) and ref($keywords) eq 'HASH') {
        my $prefix;
        if (defined $keywords->{join}) {
            $prefix = $self->__get_prefix($keywords->{join});
        }
        while (my ($type, $value) = each %$keywords) {
            my $query_string;

            if (ref($value) eq 'ARRAY') {
                $search_string = join '^', @$value;
                if ($type eq 'title') {
                    $query_string = 'q.enriched.url.title';
                    $params->{$query_string} = $prefix . '[' . $search_string . ']';
                }
                elsif ($type eq 'text') {
                    $query_string = 'q.enriched.url.text';
                    $params->{$query_string} = $prefix . '[' . $search_string . ']';
                }
            }
            else {
                $query_string = 'q.enriched.url.text';
                $params->{$query_string} = $value;
            }

        }
    }
    else {
        $query_string = 'q.enriched.url.text';
        $params->{$query_string} = $keywords;
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

        my $prefix = $self->__get_prefix;

        $params->{$query_string} = $prefix . '[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = $taxonomy 
    }

    return $params;
}

sub _format_concepts_query {
    my $self = shift;

    my $concepts = $self->{_concepts};

    my $params       = {};
    my $query_string = 'q.enriched.url.concepts.concept.text';

    my $prefix = $self->__get_prefix;

    if (ref($concept) and ref($concept) eq 'ARRAY') {
        my $search_string = join '^', @{ $concept };
        $params->{$query_string} = $prefix . '[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = $prefix . '[' . $concept . ']';
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

            my $prefix = $self->__get_prefix;

            $params->{$type_query}   = $type;
            $params->{$entity_query} = $prefix . '[' . $search_string . ']';
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
                    my $prefix = $self->__get_prefix;

                    $action = 'acton.verb.text=' . $prefix . '[' . $search_string . ']';
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

    # |type=positive,score=>0.5|

    if (ref($sentiment) and ref($sentiment) eq 'HASH') {
        my $sent_string = '|type=';
 
        if (my $type = $sentiment->{type}) {
            if (ref($type) and ref($type) eq 'ARRAY') {
                my $prefix = $self->__get_prefix;
                my $search_string = join '^', @$type;
                $sent_string .= $prefix . '[' . $search_string . '],';
            }
            else {
                $sent_string .= $type . ',';
            }
        }
        else {
            cluck "No type key detected in sentiment query, cannot build";
            return undef;
        }

        if (my $score = $sentiment->{score}) {
            if (ref $score and ref($score) eq 'HASH') {
                my $value    = $score->{value};
                my $operator = $score->{operator};

                unless ($operator =~ /(?:<|<=|>=|=|>)/) {
                    cluck "Invalid operator, cannot format sentiment query";
                    return undef;
                }

                $sent_string .= 'score' . $operator . $value . '|';
            }
            else {
                cluck "Unsupported data structure in sentiment value, cannot build sentiment query";
                return undef;
            }
        }
        else {
            cluck "No score key detected in sentiment query, cannot build";
            return undef;
        }

        $params->{$query_string} = $sent_string;
    }
    else {
        cluck "Unsupported data structure in sentiment value, cannot build sentiment query";
        return undef;
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

sub __get_prefix {
    my $self = shift;
    my $join = shift or undef;

    $join ||= defined $self->{_join} ? $self->{_join} : 'OR';

    unless ($join =~ /(?:^\bOR\b$|^\bAND\b$)/) {
        cluck "Unsupported join type, defaulting to OR";
        return 'O';
    }

    my ($prefix) = split '', $join;
    $prefix = uc($prefix);

    return $prefix;
}

1;
