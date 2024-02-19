SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: action_text_rich_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_text_rich_texts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    body text,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_text_rich_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_text_rich_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_text_rich_texts_id_seq OWNED BY public.action_text_rich_texts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_box_order_requirements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_box_order_requirements (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    box_id bigint NOT NULL,
    quantity numeric(8,0),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    stock numeric(8,0),
    ordered numeric(8,0)
);


--
-- Name: article_box_order_requirements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.article_box_order_requirements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_box_order_requirements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.article_box_order_requirements_id_seq OWNED BY public.article_box_order_requirements.id;


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    price numeric(8,5),
    unit character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ingredient_id bigint NOT NULL,
    notes text,
    quantity numeric(8,1),
    stock numeric(8,0) DEFAULT 0.0 NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    order_limit numeric(8,0),
    packing_type integer DEFAULT 0 NOT NULL,
    needs_cooling boolean DEFAULT false NOT NULL,
    nr integer
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: boxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boxes (
    id bigint NOT NULL,
    datetime timestamp(6) without time zone,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    box_type integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL
);


--
-- Name: meals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meals (
    id bigint NOT NULL,
    datetime timestamp(6) without time zone,
    recipe_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    estimated_share numeric(3,2) DEFAULT 1.0,
    optional boolean DEFAULT false NOT NULL,
    name character varying,
    lama_slot_uuid uuid,
    bundle boolean DEFAULT false NOT NULL
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    servings numeric(6,2) DEFAULT 1.0,
    lama_uuid uuid,
    diet_notes character varying
);


--
-- Name: box_meals; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.box_meals AS
 SELECT meals.id AS meal_id,
    recipes.id AS recipe_id,
    ( SELECT boxes.id
           FROM public.boxes
          WHERE (boxes.datetime <= meals.datetime)
          ORDER BY boxes.datetime DESC
         LIMIT 1) AS box_id
   FROM (public.meals
     JOIN public.recipes ON ((recipes.id = meals.recipe_id)));


--
-- Name: boxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.boxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.boxes_id_seq OWNED BY public.boxes.id;


--
-- Name: calculations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculations (
    id character varying NOT NULL,
    count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: diet_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diet_participants (
    id bigint NOT NULL,
    diet_id bigint,
    participant_id bigint
);


--
-- Name: diet_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.diet_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diet_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.diet_participants_id_seq OWNED BY public.diet_participants.id;


--
-- Name: diets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diets (
    id bigint NOT NULL,
    name character varying,
    category character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lama_uuid uuid
);


--
-- Name: diets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.diets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.diets_id_seq OWNED BY public.diets.id;


--
-- Name: diets_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diets_ingredients (
    diet_id bigint,
    ingredient_id bigint
);


--
-- Name: extra_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.extra_ingredients (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    box_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    quantity numeric(7,2),
    unit character varying,
    purpose character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: extra_ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.extra_ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extra_ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.extra_ingredients_id_seq OWNED BY public.extra_ingredients.id;


--
-- Name: group_box_articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_box_articles (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    box_id bigint NOT NULL,
    article_id bigint NOT NULL,
    quantity numeric(8,0),
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: group_box_articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_box_articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_box_articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_box_articles_id_seq OWNED BY public.group_box_articles.id;


--
-- Name: group_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_changes (
    id bigint NOT NULL,
    participant_id bigint NOT NULL,
    group_id bigint,
    timeframe tsrange NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: group_meal_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_meal_participations (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    meal_id bigint NOT NULL,
    participant_id bigint NOT NULL,
    lama_imported boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lama_uuid uuid,
    hunger_factor numeric(4,3) DEFAULT 1.0 NOT NULL,
    packing_lane_id bigint,
    internal_name character varying,
    skip_mandatory_meals boolean DEFAULT false NOT NULL
);


--
-- Name: meal_selections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meal_selections (
    group_id bigint NOT NULL,
    meal_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: group_meals; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_meals AS
 WITH group_meal_origin AS (
         SELECT DISTINCT group_meal_participations.group_id,
            group_meal_participations.meal_id,
            0 AS origin
           FROM public.group_meal_participations
        UNION ALL
         SELECT meal_selections.group_id,
            meal_selections.meal_id,
            1 AS origin
           FROM public.meal_selections
        UNION ALL
         SELECT groups.id AS group_id,
            meals.id AS meal_id,
            2 AS origin
           FROM (public.meals
             CROSS JOIN public.groups)
          WHERE ((meals.optional = false) AND (groups.skip_mandatory_meals = false))
        )
 SELECT group_meal_origin.group_id,
    group_meal_origin.meal_id,
    max(group_meal_origin.origin) AS origin
   FROM group_meal_origin
  GROUP BY group_meal_origin.group_id, group_meal_origin.meal_id;


--
-- Name: participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participants (
    id bigint NOT NULL,
    group_id bigint,
    age integer,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lama_uuid uuid,
    comment character varying,
    external_id character varying
);


--
-- Name: group_meal_participants; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_meal_participants AS
 WITH mandatory_or_chosen_group_meals AS (
         SELECT group_meals.group_id,
            group_meals.meal_id,
            meals.datetime
           FROM (public.group_meals
             JOIN public.meals ON ((group_meals.meal_id = meals.id)))
          WHERE (group_meals.origin = ANY (ARRAY[1, 2]))
        )
 SELECT group_meal_participations.group_id,
    group_meal_participations.meal_id,
    group_meal_participations.participant_id
   FROM public.group_meal_participations
UNION
 SELECT mandatory_or_chosen_group_meals.group_id,
    mandatory_or_chosen_group_meals.meal_id,
    participants.id AS participant_id
   FROM (mandatory_or_chosen_group_meals
     JOIN public.participants USING (group_id))
  WHERE (NOT (EXISTS ( SELECT
           FROM public.group_changes
          WHERE ((group_changes.participant_id = participants.id) AND (group_changes.timeframe @> mandatory_or_chosen_group_meals.datetime)))))
UNION
 SELECT mandatory_or_chosen_group_meals.group_id,
    mandatory_or_chosen_group_meals.meal_id,
    group_changes.participant_id
   FROM (mandatory_or_chosen_group_meals
     JOIN public.group_changes ON (((group_changes.timeframe @> mandatory_or_chosen_group_meals.datetime) AND (group_changes.group_id = mandatory_or_chosen_group_meals.group_id))));


--
-- Name: ingredient_alternatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_alternatives (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    alternative_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: negative_diet_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.negative_diet_ingredients (
    diet_id bigint,
    recipe_ingredient_id bigint
);


--
-- Name: positive_diet_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positive_diet_ingredients (
    diet_id bigint,
    recipe_ingredient_id bigint
);


--
-- Name: recipe_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_ingredients (
    id bigint NOT NULL,
    recipe_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    quantity numeric(7,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    unit character varying,
    index integer
);


--
-- Name: group_meal_participant_recipe_ingredient_subst_calculations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_meal_participant_recipe_ingredient_subst_calculations AS
 SELECT group_meal_participants.group_id,
    group_meal_participants.meal_id,
    group_meal_participants.participant_id,
    recipe_ingredients.id AS recipe_ingredient_id,
    recipe_ingredients.unit,
    intermediate_calculations.normalized_quantity,
    intermediate_calculations.positive_diets_exist,
    intermediate_calculations.positive_diets_match,
    intermediate_calculations.negative_diets_match,
    intermediate_calculations.diets_match,
    intermediate_calculations.alternative_ingredient_id,
    final_calculations.include_ingredient_for_participant,
    final_calculations.final_ingredient_id
   FROM (((((public.group_meal_participants
     JOIN public.meals ON ((meals.id = group_meal_participants.meal_id)))
     JOIN public.recipes ON ((recipes.id = meals.recipe_id)))
     JOIN public.recipe_ingredients USING (recipe_id))
     CROSS JOIN LATERAL ( SELECT (recipe_ingredients.quantity / recipes.servings) AS normalized_quantity,
            (EXISTS ( SELECT
                   FROM public.positive_diet_ingredients
                  WHERE (positive_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id))) AS positive_diets_exist,
            (EXISTS ( SELECT
                   FROM (public.positive_diet_ingredients
                     JOIN public.diet_participants USING (diet_id))
                  WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (positive_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id)))) AS positive_diets_match,
            (EXISTS ( SELECT
                   FROM (public.negative_diet_ingredients
                     JOIN public.diet_participants USING (diet_id))
                  WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (negative_diet_ingredients.recipe_ingredient_id = recipe_ingredients.id)))) AS negative_diets_match,
            (EXISTS ( SELECT
                   FROM (public.diets_ingredients
                     JOIN public.diet_participants USING (diet_id))
                  WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (diets_ingredients.ingredient_id = recipe_ingredients.ingredient_id)))) AS diets_match,
            ( SELECT ingredient_alternatives.alternative_id
                   FROM (public.ingredient_alternatives
                     CROSS JOIN LATERAL ( SELECT (EXISTS ( SELECT
                                   FROM (public.diets_ingredients
                                     JOIN public.diet_participants USING (diet_id))
                                  WHERE ((diet_participants.participant_id = group_meal_participants.participant_id) AND (diets_ingredients.ingredient_id = ingredient_alternatives.alternative_id)))) AS alternative_diets_match) alternative_table)
                  WHERE ((ingredient_alternatives.ingredient_id = recipe_ingredients.ingredient_id) AND (NOT alternative_table.alternative_diets_match))
                  ORDER BY ingredient_alternatives.priority
                 LIMIT 1) AS alternative_ingredient_id) intermediate_calculations)
     CROSS JOIN LATERAL ( SELECT ((NOT intermediate_calculations.negative_diets_match) AND ((NOT intermediate_calculations.positive_diets_exist) OR intermediate_calculations.positive_diets_match)) AS include_ingredient_for_participant,
                CASE intermediate_calculations.diets_match
                    WHEN true THEN intermediate_calculations.alternative_ingredient_id
                    WHEN false THEN recipe_ingredients.ingredient_id
                    ELSE NULL::bigint
                END AS final_ingredient_id) final_calculations);


--
-- Name: hunger_factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunger_factors (
    id bigint NOT NULL,
    age integer NOT NULL,
    factor numeric(4,3) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredients (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    commodity_group character varying,
    no_buy boolean DEFAULT false NOT NULL,
    uses_hunger_factor boolean DEFAULT false NOT NULL,
    box_type integer DEFAULT 0 NOT NULL
);


--
-- Name: group_meal_participant_recipe_ingredient_calculations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_meal_participant_recipe_ingredient_calculations AS
 SELECT group_meal_participant_recipe_ingredient_subst_calculations.group_id,
    group_meal_participant_recipe_ingredient_subst_calculations.meal_id,
    group_meal_participant_recipe_ingredient_subst_calculations.participant_id,
    group_meal_participant_recipe_ingredient_subst_calculations.recipe_ingredient_id,
    group_meal_participant_recipe_ingredient_subst_calculations.unit,
    hunger_calculation.hunger_quantity,
    group_meal_participant_recipe_ingredient_subst_calculations.final_ingredient_id AS ingredient_id
   FROM (((((public.group_meal_participant_recipe_ingredient_subst_calculations
     JOIN public.participants ON ((participants.id = group_meal_participant_recipe_ingredient_subst_calculations.participant_id)))
     JOIN public.groups ON ((groups.id = group_meal_participant_recipe_ingredient_subst_calculations.group_id)))
     JOIN public.ingredients ON ((ingredients.id = group_meal_participant_recipe_ingredient_subst_calculations.final_ingredient_id)))
     LEFT JOIN public.hunger_factors USING (age))
     CROSS JOIN LATERAL ( SELECT
                CASE ingredients.uses_hunger_factor
                    WHEN true THEN ((group_meal_participant_recipe_ingredient_subst_calculations.normalized_quantity * COALESCE(hunger_factors.factor, (1)::numeric)) * groups.hunger_factor)
                    WHEN false THEN group_meal_participant_recipe_ingredient_subst_calculations.normalized_quantity
                    ELSE NULL::numeric
                END AS hunger_quantity) hunger_calculation)
  WHERE group_meal_participant_recipe_ingredient_subst_calculations.include_ingredient_for_participant;


--
-- Name: ingredient_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredient_weights (
    id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    unit character varying,
    weight numeric(7,2),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: meal_ingredient_boxes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.meal_ingredient_boxes AS
 WITH meal_ingredients(meal_id, ingredient_id) AS (
         SELECT DISTINCT group_meal_participant_recipe_ingredient_calculations.meal_id,
            group_meal_participant_recipe_ingredient_calculations.ingredient_id
           FROM public.group_meal_participant_recipe_ingredient_calculations
        )
 SELECT meal_ingredients.meal_id,
    meal_ingredients.ingredient_id,
    ( SELECT boxes.id
           FROM public.boxes
          WHERE ((boxes.datetime <= meals.datetime) AND (meals.bundle OR (boxes.box_type = 1) OR ((boxes.box_type = 0) AND (ingredients.box_type <> 1)) OR ((boxes.box_type = 2) AND (ingredients.box_type = 2))))
          ORDER BY boxes.datetime DESC
         LIMIT 1) AS box_id
   FROM ((meal_ingredients
     JOIN public.ingredients ON ((ingredients.id = meal_ingredients.ingredient_id)))
     JOIN public.meals ON ((meals.id = meal_ingredients.meal_id)));


--
-- Name: group_box_ingredient_units; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_box_ingredient_units AS
 WITH ingredient_sums AS (
         SELECT group_meal_participant_recipe_ingredient_calculations.group_id,
            meal_ingredient_boxes.box_id,
            group_meal_participant_recipe_ingredient_calculations.ingredient_id,
            group_meal_participant_recipe_ingredient_calculations.unit,
            sum(group_meal_participant_recipe_ingredient_calculations.hunger_quantity) AS quantity
           FROM (public.group_meal_participant_recipe_ingredient_calculations
             JOIN public.meal_ingredient_boxes USING (meal_id, ingredient_id))
          GROUP BY group_meal_participant_recipe_ingredient_calculations.group_id, meal_ingredient_boxes.box_id, group_meal_participant_recipe_ingredient_calculations.ingredient_id, group_meal_participant_recipe_ingredient_calculations.unit
        ), weighted_ingredient_sums AS (
         SELECT ingredient_sums.group_id,
            ingredient_sums.box_id,
            ingredient_sums.ingredient_id,
            packing.pack_unit,
            packing.pack_quantity
           FROM (((ingredient_sums
             LEFT JOIN public.ingredient_weights USING (ingredient_id, unit))
             CROSS JOIN LATERAL ( SELECT
                        CASE
                            WHEN (ingredient_weights.weight IS NOT NULL) THEN (ingredient_weights.weight * ingredient_sums.quantity)
                            WHEN ((ingredient_sums.unit)::text = 'g'::text) THEN ingredient_sums.quantity
                            ELSE NULL::numeric
                        END AS resulting_weight) weight_calculation)
             CROSS JOIN LATERAL ( SELECT COALESCE(weight_calculation.resulting_weight, ingredient_sums.quantity) AS pack_quantity,
                    ( SELECT
                                CASE
                                    WHEN (weight_calculation.resulting_weight IS NOT NULL) THEN 'g'::character varying
                                    ELSE ingredient_sums.unit
                                END AS unit) AS pack_unit) packing)
        ), weighted_ingredient_sums_with_extra_ingredients AS (
         SELECT weighted_ingredient_sums.group_id,
            weighted_ingredient_sums.box_id,
            weighted_ingredient_sums.ingredient_id,
            weighted_ingredient_sums.pack_unit AS unit,
            weighted_ingredient_sums.pack_quantity AS quantity
           FROM weighted_ingredient_sums
        UNION ALL
         SELECT extra_ingredients.group_id,
            extra_ingredients.box_id,
            extra_ingredients.ingredient_id,
            extra_ingredients.unit,
            extra_ingredients.quantity
           FROM public.extra_ingredients
        )
 SELECT weighted_ingredient_sums_with_extra_ingredients.group_id,
    weighted_ingredient_sums_with_extra_ingredients.box_id,
    weighted_ingredient_sums_with_extra_ingredients.ingredient_id,
    weighted_ingredient_sums_with_extra_ingredients.unit,
    (sum(weighted_ingredient_sums_with_extra_ingredients.quantity))::numeric(8,2) AS quantity
   FROM weighted_ingredient_sums_with_extra_ingredients
  GROUP BY weighted_ingredient_sums_with_extra_ingredients.group_id, weighted_ingredient_sums_with_extra_ingredients.box_id, weighted_ingredient_sums_with_extra_ingredients.ingredient_id, weighted_ingredient_sums_with_extra_ingredients.unit;


--
-- Name: group_box_ingredient_unit_caches; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.group_box_ingredient_unit_caches AS
 SELECT group_box_ingredient_units.group_id,
    group_box_ingredient_units.box_id,
    group_box_ingredient_units.ingredient_id,
    group_box_ingredient_units.unit,
    group_box_ingredient_units.quantity
   FROM public.group_box_ingredient_units
  WITH NO DATA;


--
-- Name: group_boxes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.group_boxes AS
 SELECT groups.id AS group_id,
    boxes.id AS box_id
   FROM (public.groups
     CROSS JOIN public.boxes);


--
-- Name: group_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_changes_id_seq OWNED BY public.group_changes.id;


--
-- Name: group_meal_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_meal_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_meal_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_meal_participations_id_seq OWNED BY public.group_meal_participations.id;


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: hoards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hoards (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    quantity numeric(8,0) NOT NULL,
    until timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    missing_quantity numeric(8,0) DEFAULT 0.0 NOT NULL
);


--
-- Name: hoards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hoards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hoards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hoards_id_seq OWNED BY public.hoards.id;


--
-- Name: hunger_factors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hunger_factors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hunger_factors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hunger_factors_id_seq OWNED BY public.hunger_factors.id;


--
-- Name: ingredient_alternatives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredient_alternatives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_alternatives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredient_alternatives_id_seq OWNED BY public.ingredient_alternatives.id;


--
-- Name: ingredient_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredient_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredient_weights_id_seq OWNED BY public.ingredient_weights.id;


--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ingredients_id_seq OWNED BY public.ingredients.id;


--
-- Name: meals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.meals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.meals_id_seq OWNED BY public.meals.id;


--
-- Name: missing_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.missing_ingredients (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    box_id bigint NOT NULL,
    ingredient_id bigint NOT NULL,
    quantity numeric(8,2),
    unit character varying,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: missing_ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.missing_ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: missing_ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.missing_ingredients_id_seq OWNED BY public.missing_ingredients.id;


--
-- Name: order_articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_articles (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    article_id bigint NOT NULL,
    quantity_ordered numeric(8,0) DEFAULT 0.0,
    quantity_delivered numeric(8,0) DEFAULT 0.0,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: order_articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_articles_id_seq OWNED BY public.order_articles.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    coverage tsrange,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    state integer DEFAULT 0 NOT NULL
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: packing_lane_article_stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packing_lane_article_stocks (
    id bigint NOT NULL,
    packing_lane_id bigint NOT NULL,
    article_id bigint NOT NULL,
    quantity numeric(8,0) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    box_id bigint NOT NULL
);


--
-- Name: packing_lane_article_stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packing_lane_article_stocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packing_lane_article_stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packing_lane_article_stocks_id_seq OWNED BY public.packing_lane_article_stocks.id;


--
-- Name: packing_lanes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packing_lanes (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: packing_lanes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packing_lanes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packing_lanes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packing_lanes_id_seq OWNED BY public.packing_lanes.id;


--
-- Name: participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.participants_id_seq OWNED BY public.participants.id;


--
-- Name: recipe_ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipe_ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipe_ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipe_ingredients_id_seq OWNED BY public.recipe_ingredients.id;


--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipes_id_seq OWNED BY public.recipes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stock_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_changes (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    user_id bigint NOT NULL,
    quantity numeric(8,0) NOT NULL,
    result numeric(8,0) NOT NULL,
    reference character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: stock_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_changes_id_seq OWNED BY public.stock_changes.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    delivery_time integer DEFAULT 72 NOT NULL,
    address text,
    email character varying,
    phone character varying
);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp(6) without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    role integer DEFAULT 0 NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: action_text_rich_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts ALTER COLUMN id SET DEFAULT nextval('public.action_text_rich_texts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: article_box_order_requirements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_box_order_requirements ALTER COLUMN id SET DEFAULT nextval('public.article_box_order_requirements_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: boxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes ALTER COLUMN id SET DEFAULT nextval('public.boxes_id_seq'::regclass);


--
-- Name: diet_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diet_participants ALTER COLUMN id SET DEFAULT nextval('public.diet_participants_id_seq'::regclass);


--
-- Name: diets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diets ALTER COLUMN id SET DEFAULT nextval('public.diets_id_seq'::regclass);


--
-- Name: extra_ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_ingredients ALTER COLUMN id SET DEFAULT nextval('public.extra_ingredients_id_seq'::regclass);


--
-- Name: group_box_articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_box_articles ALTER COLUMN id SET DEFAULT nextval('public.group_box_articles_id_seq'::regclass);


--
-- Name: group_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_changes ALTER COLUMN id SET DEFAULT nextval('public.group_changes_id_seq'::regclass);


--
-- Name: group_meal_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_meal_participations ALTER COLUMN id SET DEFAULT nextval('public.group_meal_participations_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: hoards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hoards ALTER COLUMN id SET DEFAULT nextval('public.hoards_id_seq'::regclass);


--
-- Name: hunger_factors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunger_factors ALTER COLUMN id SET DEFAULT nextval('public.hunger_factors_id_seq'::regclass);


--
-- Name: ingredient_alternatives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_alternatives ALTER COLUMN id SET DEFAULT nextval('public.ingredient_alternatives_id_seq'::regclass);


--
-- Name: ingredient_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_weights ALTER COLUMN id SET DEFAULT nextval('public.ingredient_weights_id_seq'::regclass);


--
-- Name: ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients ALTER COLUMN id SET DEFAULT nextval('public.ingredients_id_seq'::regclass);


--
-- Name: meals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meals ALTER COLUMN id SET DEFAULT nextval('public.meals_id_seq'::regclass);


--
-- Name: missing_ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missing_ingredients ALTER COLUMN id SET DEFAULT nextval('public.missing_ingredients_id_seq'::regclass);


--
-- Name: order_articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_articles ALTER COLUMN id SET DEFAULT nextval('public.order_articles_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: packing_lane_article_stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lane_article_stocks ALTER COLUMN id SET DEFAULT nextval('public.packing_lane_article_stocks_id_seq'::regclass);


--
-- Name: packing_lanes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lanes ALTER COLUMN id SET DEFAULT nextval('public.packing_lanes_id_seq'::regclass);


--
-- Name: participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants ALTER COLUMN id SET DEFAULT nextval('public.participants_id_seq'::regclass);


--
-- Name: recipe_ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients ALTER COLUMN id SET DEFAULT nextval('public.recipe_ingredients_id_seq'::regclass);


--
-- Name: recipes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes ALTER COLUMN id SET DEFAULT nextval('public.recipes_id_seq'::regclass);


--
-- Name: stock_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_changes ALTER COLUMN id SET DEFAULT nextval('public.stock_changes_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: action_text_rich_texts action_text_rich_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_text_rich_texts
    ADD CONSTRAINT action_text_rich_texts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: article_box_order_requirements article_box_order_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_box_order_requirements
    ADD CONSTRAINT article_box_order_requirements_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: boxes boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boxes
    ADD CONSTRAINT boxes_pkey PRIMARY KEY (id);


--
-- Name: calculations calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_pkey PRIMARY KEY (id);


--
-- Name: diet_participants diet_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diet_participants
    ADD CONSTRAINT diet_participants_pkey PRIMARY KEY (id);


--
-- Name: diets diets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diets
    ADD CONSTRAINT diets_pkey PRIMARY KEY (id);


--
-- Name: extra_ingredients extra_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_ingredients
    ADD CONSTRAINT extra_ingredients_pkey PRIMARY KEY (id);


--
-- Name: group_box_articles group_box_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_box_articles
    ADD CONSTRAINT group_box_articles_pkey PRIMARY KEY (id);


--
-- Name: group_changes group_changes_participant_id_timeframe_excl; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_changes
    ADD CONSTRAINT group_changes_participant_id_timeframe_excl EXCLUDE USING gist (participant_id WITH =, timeframe WITH &&);


--
-- Name: group_changes group_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_changes
    ADD CONSTRAINT group_changes_pkey PRIMARY KEY (id);


--
-- Name: group_meal_participations group_meal_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_meal_participations
    ADD CONSTRAINT group_meal_participations_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: hoards hoards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hoards
    ADD CONSTRAINT hoards_pkey PRIMARY KEY (id);


--
-- Name: hunger_factors hunger_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunger_factors
    ADD CONSTRAINT hunger_factors_pkey PRIMARY KEY (id);


--
-- Name: ingredient_alternatives ingredient_alternatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_alternatives
    ADD CONSTRAINT ingredient_alternatives_pkey PRIMARY KEY (id);


--
-- Name: ingredient_weights ingredient_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_weights
    ADD CONSTRAINT ingredient_weights_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: meal_selections meal_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meal_selections
    ADD CONSTRAINT meal_selections_pkey PRIMARY KEY (group_id, meal_id);


--
-- Name: meals meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meals
    ADD CONSTRAINT meals_pkey PRIMARY KEY (id);


--
-- Name: missing_ingredients missing_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missing_ingredients
    ADD CONSTRAINT missing_ingredients_pkey PRIMARY KEY (id);


--
-- Name: order_articles order_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_articles
    ADD CONSTRAINT order_articles_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: packing_lane_article_stocks packing_lane_article_stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lane_article_stocks
    ADD CONSTRAINT packing_lane_article_stocks_pkey PRIMARY KEY (id);


--
-- Name: packing_lanes packing_lanes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lanes
    ADD CONSTRAINT packing_lanes_pkey PRIMARY KEY (id);


--
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);


--
-- Name: recipe_ingredients recipe_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stock_changes stock_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_changes
    ADD CONSTRAINT stock_changes_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_action_text_rich_texts_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_action_text_rich_texts_uniqueness ON public.action_text_rich_texts USING btree (record_type, record_id, name);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_article_box_order_requirements_on_article_and_box; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_article_box_order_requirements_on_article_and_box ON public.article_box_order_requirements USING btree (article_id, box_id);


--
-- Name: index_article_box_order_requirements_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_article_box_order_requirements_on_article_id ON public.article_box_order_requirements USING btree (article_id);


--
-- Name: index_article_box_order_requirements_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_article_box_order_requirements_on_box_id ON public.article_box_order_requirements USING btree (box_id);


--
-- Name: index_articles_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_ingredient_id ON public.articles USING btree (ingredient_id);


--
-- Name: index_articles_on_nr; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_articles_on_nr ON public.articles USING btree (nr);


--
-- Name: index_articles_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_supplier_id ON public.articles USING btree (supplier_id);


--
-- Name: index_boxes_on_datetime; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_boxes_on_datetime ON public.boxes USING btree (datetime);


--
-- Name: index_diet_participants_on_diet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diet_participants_on_diet_id ON public.diet_participants USING btree (diet_id);


--
-- Name: index_diet_participants_on_diet_id_and_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_diet_participants_on_diet_id_and_participant_id ON public.diet_participants USING btree (diet_id, participant_id);


--
-- Name: index_diet_participants_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diet_participants_on_participant_id ON public.diet_participants USING btree (participant_id);


--
-- Name: index_diets_ingredients_on_diet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diets_ingredients_on_diet_id ON public.diets_ingredients USING btree (diet_id);


--
-- Name: index_diets_ingredients_on_diet_id_and_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_diets_ingredients_on_diet_id_and_ingredient_id ON public.diets_ingredients USING btree (diet_id, ingredient_id);


--
-- Name: index_diets_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diets_ingredients_on_ingredient_id ON public.diets_ingredients USING btree (ingredient_id);


--
-- Name: index_diets_on_lama_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_diets_on_lama_uuid ON public.diets USING btree (lama_uuid);


--
-- Name: index_diets_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_diets_on_name ON public.diets USING btree (name);


--
-- Name: index_extra_ingredients_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_extra_ingredients_on_box_id ON public.extra_ingredients USING btree (box_id);


--
-- Name: index_extra_ingredients_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_extra_ingredients_on_group_id ON public.extra_ingredients USING btree (group_id);


--
-- Name: index_extra_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_extra_ingredients_on_ingredient_id ON public.extra_ingredients USING btree (ingredient_id);


--
-- Name: index_group_box_articles_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_box_articles_on_article_id ON public.group_box_articles USING btree (article_id);


--
-- Name: index_group_box_articles_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_box_articles_on_box_id ON public.group_box_articles USING btree (box_id);


--
-- Name: index_group_box_articles_on_group_box_and_article; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_box_articles_on_group_box_and_article ON public.group_box_articles USING btree (group_id, box_id, article_id);


--
-- Name: index_group_box_articles_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_box_articles_on_group_id ON public.group_box_articles USING btree (group_id);


--
-- Name: index_group_changes_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_changes_on_group_id ON public.group_changes USING btree (group_id);


--
-- Name: index_group_changes_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_changes_on_participant_id ON public.group_changes USING btree (participant_id);


--
-- Name: index_group_meal_participations_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_meal_participations_on_group_id ON public.group_meal_participations USING btree (group_id);


--
-- Name: index_group_meal_participations_on_group_meal_participant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_meal_participations_on_group_meal_participant ON public.group_meal_participations USING btree (group_id, meal_id, participant_id);


--
-- Name: index_group_meal_participations_on_meal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_meal_participations_on_meal_id ON public.group_meal_participations USING btree (meal_id);


--
-- Name: index_group_meal_participations_on_participant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_meal_participations_on_participant_id ON public.group_meal_participations USING btree (participant_id);


--
-- Name: index_groups_on_internal_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_internal_name ON public.groups USING btree (internal_name);


--
-- Name: index_groups_on_lama_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_lama_uuid ON public.groups USING btree (lama_uuid);


--
-- Name: index_groups_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_name ON public.groups USING btree (name);


--
-- Name: index_groups_on_packing_lane_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_packing_lane_id ON public.groups USING btree (packing_lane_id);


--
-- Name: index_hoards_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hoards_on_article_id ON public.hoards USING btree (article_id);


--
-- Name: index_hunger_factors_on_age; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_hunger_factors_on_age ON public.hunger_factors USING btree (age);


--
-- Name: index_ingredient_alternatives_on_alternative_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredient_alternatives_on_alternative_id ON public.ingredient_alternatives USING btree (alternative_id);


--
-- Name: index_ingredient_alternatives_on_ingredient_alternative; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ingredient_alternatives_on_ingredient_alternative ON public.ingredient_alternatives USING btree (ingredient_id, alternative_id);


--
-- Name: index_ingredient_alternatives_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredient_alternatives_on_ingredient_id ON public.ingredient_alternatives USING btree (ingredient_id);


--
-- Name: index_ingredient_alternatives_on_ingredient_id_and_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ingredient_alternatives_on_ingredient_id_and_priority ON public.ingredient_alternatives USING btree (ingredient_id, priority);


--
-- Name: index_ingredient_weights_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ingredient_weights_on_ingredient_id ON public.ingredient_weights USING btree (ingredient_id);


--
-- Name: index_ingredient_weights_on_ingredient_id_and_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ingredient_weights_on_ingredient_id_and_unit ON public.ingredient_weights USING btree (ingredient_id, unit);


--
-- Name: index_ingredients_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ingredients_on_name ON public.ingredients USING btree (name);


--
-- Name: index_meal_selections_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meal_selections_on_group_id ON public.meal_selections USING btree (group_id);


--
-- Name: index_meal_selections_on_meal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meal_selections_on_meal_id ON public.meal_selections USING btree (meal_id);


--
-- Name: index_meals_on_lama_slot_uuid_and_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meals_on_lama_slot_uuid_and_recipe_id ON public.meals USING btree (lama_slot_uuid, recipe_id);


--
-- Name: index_meals_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meals_on_recipe_id ON public.meals USING btree (recipe_id);


--
-- Name: index_missing_ingredients_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_missing_ingredients_on_box_id ON public.missing_ingredients USING btree (box_id);


--
-- Name: index_missing_ingredients_on_group_box_ingredient_and_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_missing_ingredients_on_group_box_ingredient_and_unit ON public.missing_ingredients USING btree (group_id, box_id, ingredient_id, unit);


--
-- Name: index_missing_ingredients_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_missing_ingredients_on_group_id ON public.missing_ingredients USING btree (group_id);


--
-- Name: index_missing_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_missing_ingredients_on_ingredient_id ON public.missing_ingredients USING btree (ingredient_id);


--
-- Name: index_negative_diet_ingredients_diet_recipe_ingredient; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_negative_diet_ingredients_diet_recipe_ingredient ON public.negative_diet_ingredients USING btree (diet_id, recipe_ingredient_id);


--
-- Name: index_negative_diet_ingredients_on_diet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_negative_diet_ingredients_on_diet_id ON public.negative_diet_ingredients USING btree (diet_id);


--
-- Name: index_negative_diet_ingredients_on_recipe_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_negative_diet_ingredients_on_recipe_ingredient_id ON public.negative_diet_ingredients USING btree (recipe_ingredient_id);


--
-- Name: index_order_articles_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_articles_on_article_id ON public.order_articles USING btree (article_id);


--
-- Name: index_order_articles_on_order_and_article; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_order_articles_on_order_and_article ON public.order_articles USING btree (order_id, article_id);


--
-- Name: index_order_articles_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_order_articles_on_order_id ON public.order_articles USING btree (order_id);


--
-- Name: index_orders_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_supplier_id ON public.orders USING btree (supplier_id);


--
-- Name: index_packing_lane_article_stocks_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packing_lane_article_stocks_on_article_id ON public.packing_lane_article_stocks USING btree (article_id);


--
-- Name: index_packing_lane_article_stocks_on_box_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packing_lane_article_stocks_on_box_id ON public.packing_lane_article_stocks USING btree (box_id);


--
-- Name: index_packing_lane_article_stocks_on_packing_lane_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packing_lane_article_stocks_on_packing_lane_id ON public.packing_lane_article_stocks USING btree (packing_lane_id);


--
-- Name: index_packing_lanes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_packing_lanes_on_name ON public.packing_lanes USING btree (name);


--
-- Name: index_participants_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_participants_on_external_id ON public.participants USING btree (external_id);


--
-- Name: index_participants_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_participants_on_group_id ON public.participants USING btree (group_id);


--
-- Name: index_participants_on_lama_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_participants_on_lama_uuid ON public.participants USING btree (lama_uuid);


--
-- Name: index_positive_diet_ingredients_diet_recipe_ingredient; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_positive_diet_ingredients_diet_recipe_ingredient ON public.positive_diet_ingredients USING btree (diet_id, recipe_ingredient_id);


--
-- Name: index_positive_diet_ingredients_on_diet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_positive_diet_ingredients_on_diet_id ON public.positive_diet_ingredients USING btree (diet_id);


--
-- Name: index_positive_diet_ingredients_on_recipe_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_positive_diet_ingredients_on_recipe_ingredient_id ON public.positive_diet_ingredients USING btree (recipe_ingredient_id);


--
-- Name: index_recipe_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipe_ingredients_on_ingredient_id ON public.recipe_ingredients USING btree (ingredient_id);


--
-- Name: index_recipe_ingredients_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipe_ingredients_on_recipe_id ON public.recipe_ingredients USING btree (recipe_id);


--
-- Name: index_recipe_ingredients_on_recipe_id_and_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recipe_ingredients_on_recipe_id_and_index ON public.recipe_ingredients USING btree (recipe_id, index);


--
-- Name: index_recipes_on_lama_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recipes_on_lama_uuid ON public.recipes USING btree (lama_uuid);


--
-- Name: index_recipes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recipes_on_name ON public.recipes USING btree (name);


--
-- Name: index_stock_changes_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_changes_on_article_id ON public.stock_changes USING btree (article_id);


--
-- Name: index_stock_changes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stock_changes_on_user_id ON public.stock_changes USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: packing_lane_article_stock_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX packing_lane_article_stock_unique ON public.packing_lane_article_stocks USING btree (packing_lane_id, box_id, article_id);


--
-- Name: group_meal_participations fk_rails_1725821e2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_meal_participations
    ADD CONSTRAINT fk_rails_1725821e2b FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: recipe_ingredients fk_rails_176a228c1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT fk_rails_176a228c1e FOREIGN KEY (recipe_id) REFERENCES public.recipes(id);


--
-- Name: group_box_articles fk_rails_17ae4a4ed3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_box_articles
    ADD CONSTRAINT fk_rails_17ae4a4ed3 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: recipe_ingredients fk_rails_209d9afca6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT fk_rails_209d9afca6 FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: ingredient_weights fk_rails_22058e01bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_weights
    ADD CONSTRAINT fk_rails_22058e01bd FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: packing_lane_article_stocks fk_rails_25ae3a0043; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lane_article_stocks
    ADD CONSTRAINT fk_rails_25ae3a0043 FOREIGN KEY (box_id) REFERENCES public.boxes(id);


--
-- Name: packing_lane_article_stocks fk_rails_269ba67569; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lane_article_stocks
    ADD CONSTRAINT fk_rails_269ba67569 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: extra_ingredients fk_rails_26f4aa690d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_ingredients
    ADD CONSTRAINT fk_rails_26f4aa690d FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: group_meal_participations fk_rails_2f40eaaf25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_meal_participations
    ADD CONSTRAINT fk_rails_2f40eaaf25 FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: participants fk_rails_374e5e814f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT fk_rails_374e5e814f FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: groups fk_rails_42dd45b21f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_42dd45b21f FOREIGN KEY (packing_lane_id) REFERENCES public.packing_lanes(id);


--
-- Name: missing_ingredients fk_rails_4370849a16; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missing_ingredients
    ADD CONSTRAINT fk_rails_4370849a16 FOREIGN KEY (box_id) REFERENCES public.boxes(id) ON DELETE CASCADE;


--
-- Name: order_articles fk_rails_44e6c21781; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_articles
    ADD CONSTRAINT fk_rails_44e6c21781 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: missing_ingredients fk_rails_5c32f6c8e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missing_ingredients
    ADD CONSTRAINT fk_rails_5c32f6c8e3 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: stock_changes fk_rails_5da56c3410; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_changes
    ADD CONSTRAINT fk_rails_5da56c3410 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: group_meal_participations fk_rails_5e60706d21; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_meal_participations
    ADD CONSTRAINT fk_rails_5e60706d21 FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: group_box_articles fk_rails_64228b658f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_box_articles
    ADD CONSTRAINT fk_rails_64228b658f FOREIGN KEY (box_id) REFERENCES public.boxes(id) ON DELETE CASCADE;


--
-- Name: group_box_articles fk_rails_643c2a5233; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_box_articles
    ADD CONSTRAINT fk_rails_643c2a5233 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: extra_ingredients fk_rails_7cff366698; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_ingredients
    ADD CONSTRAINT fk_rails_7cff366698 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: meal_selections fk_rails_8206118345; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meal_selections
    ADD CONSTRAINT fk_rails_8206118345 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_changes fk_rails_84842f6b5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_changes
    ADD CONSTRAINT fk_rails_84842f6b5b FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- Name: packing_lane_article_stocks fk_rails_84ce9b21f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packing_lane_article_stocks
    ADD CONSTRAINT fk_rails_84ce9b21f5 FOREIGN KEY (packing_lane_id) REFERENCES public.packing_lanes(id);


--
-- Name: hoards fk_rails_8a9739b4d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hoards
    ADD CONSTRAINT fk_rails_8a9739b4d7 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: extra_ingredients fk_rails_8ba7ddbf1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.extra_ingredients
    ADD CONSTRAINT fk_rails_8ba7ddbf1f FOREIGN KEY (box_id) REFERENCES public.boxes(id);


--
-- Name: articles fk_rails_927e74121d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_927e74121d FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: ingredient_alternatives fk_rails_92af5f742e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_alternatives
    ADD CONSTRAINT fk_rails_92af5f742e FOREIGN KEY (alternative_id) REFERENCES public.ingredients(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: group_changes fk_rails_a92dff67da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_changes
    ADD CONSTRAINT fk_rails_a92dff67da FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: ingredient_alternatives fk_rails_b3524c94d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredient_alternatives
    ADD CONSTRAINT fk_rails_b3524c94d3 FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id);


--
-- Name: articles fk_rails_bdcb12def8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT fk_rails_bdcb12def8 FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: order_articles fk_rails_be47438f30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_articles
    ADD CONSTRAINT fk_rails_be47438f30 FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: meal_selections fk_rails_c3d4f0d8b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meal_selections
    ADD CONSTRAINT fk_rails_c3d4f0d8b8 FOREIGN KEY (meal_id) REFERENCES public.meals(id);


--
-- Name: orders fk_rails_d426350910; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_d426350910 FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: stock_changes fk_rails_de49fe5502; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_changes
    ADD CONSTRAINT fk_rails_de49fe5502 FOREIGN KEY (article_id) REFERENCES public.articles(id);


--
-- Name: article_box_order_requirements fk_rails_f010a242f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_box_order_requirements
    ADD CONSTRAINT fk_rails_f010a242f2 FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: meals fk_rails_f5c19203d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meals
    ADD CONSTRAINT fk_rails_f5c19203d6 FOREIGN KEY (recipe_id) REFERENCES public.recipes(id);


--
-- Name: article_box_order_requirements fk_rails_fad3d11b4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_box_order_requirements
    ADD CONSTRAINT fk_rails_fad3d11b4d FOREIGN KEY (box_id) REFERENCES public.boxes(id) ON DELETE CASCADE;


--
-- Name: missing_ingredients fk_rails_feb31155ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missing_ingredients
    ADD CONSTRAINT fk_rails_feb31155ae FOREIGN KEY (ingredient_id) REFERENCES public.ingredients(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240219215046'),
('20230723191003'),
('20230626183846'),
('20230626183741'),
('20230619203540'),
('20230619193439'),
('20230514175450'),
('20230510193610'),
('20230325103344'),
('20230317161948'),
('20230308232353'),
('20230305220300'),
('20230305202100'),
('20230305153735'),
('20221212175242'),
('20221211121557');

