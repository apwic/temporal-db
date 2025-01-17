PGDMP     5                	    {            temporal    14.9 (Homebrew)    14.9 (Homebrew) 1    ?           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            @           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            A           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            B           1262    16384    temporal    DATABASE     S   CREATE DATABASE temporal WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'C';
    DROP DATABASE temporal;
                anca    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                anca    false            C           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   anca    false    3            U           1247    16387    valid_period    TYPE     W   CREATE TYPE public.valid_period AS (
	start_timestamp bigint,
	end_timestamp bigint
);
    DROP TYPE public.valid_period;
       public          anca    false    3            X           1247    16389    valid_period_domain    DOMAIN     �   CREATE DOMAIN public.valid_period_domain AS public.valid_period
	CONSTRAINT valid_period_domain_check CHECK (((VALUE).start_timestamp <= (VALUE).end_timestamp));
 (   DROP DOMAIN public.valid_period_domain;
       public          anca    false    3    853            �            1255    16433 $   customer_deletion(character varying) 	   PROCEDURE     �   CREATE PROCEDURE public.customer_deletion(IN input_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "customer" WHERE "customer"."name" = input_name;
    COMMIT;
END;
$$;
 J   DROP PROCEDURE public.customer_deletion(IN input_name character varying);
       public          anca    false    3            �            1255    16431 A   customer_insertion(character varying, public.valid_period_domain) 	   PROCEDURE     �  CREATE PROCEDURE public.customer_insertion(IN input_name character varying, IN input_subscription_period public.valid_period_domain)
    LANGUAGE plpgsql
    AS $$
DECLARE
    found BOOLEAN;
    coalesced_period valid_period_domain;
BEGIN
    -- Check if the customer already exists
    SELECT EXISTS(
        SELECT 1
        FROM "customer"
        WHERE "customer"."name" = input_name
        AND temporal_can_merge("customer"."subscription_period", input_subscription_period)
    ) INTO found;

    IF found THEN
        -- Insert the new period
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, input_subscription_period);

        -- Get coalesced period
        WITH "temp_table" AS (
            SELECT temporal_coalesce_single("customer"."subscription_period") AS "period"
            FROM "customer"
            WHERE "customer"."name" = input_name
            AND temporal_can_merge("customer"."subscription_period", input_subscription_period)
        )
        SELECT ("temp_table"."period").start_timestamp, ("temp_table"."period").end_timestamp
        INTO coalesced_period
        FROM "temp_table";

        -- Delete all the periods that overlap with the new one
        DELETE FROM "customer"
        WHERE "customer"."name" = input_name
        AND temporal_can_merge("customer"."subscription_period", input_subscription_period);

        -- Insert the new period
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, coalesced_period);
    ELSE
        -- If the customer does not exist, insert it
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, input_subscription_period);
    END IF;

    -- Commit the transaction
    COMMIT;
END;
$$;
 �   DROP PROCEDURE public.customer_insertion(IN input_name character varying, IN input_subscription_period public.valid_period_domain);
       public          anca    false    856    3            �            1255    16435 D   customer_modification(character varying, public.valid_period_domain) 	   PROCEDURE       CREATE PROCEDURE public.customer_modification(IN input_name character varying, IN input_subscription_period public.valid_period_domain)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Call the deletion and insertion procedures
    CALL customer_deletion(input_name);
    CALL customer_insertion(input_name, input_subscription_period);

    -- Commit the transaction
    COMMIT;
END;
$$;
 �   DROP PROCEDURE public.customer_modification(IN input_name character varying, IN input_subscription_period public.valid_period_domain);
       public          anca    false    3    856            �            1255    16434 !   staff_deletion(character varying) 	   PROCEDURE     �   CREATE PROCEDURE public.staff_deletion(IN input_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "staff" WHERE "staff"."name" = input_name;
    COMMIT;
END;
$$;
 G   DROP PROCEDURE public.staff_deletion(IN input_name character varying);
       public          anca    false    3            �            1255    16432 >   staff_insertion(character varying, public.valid_period_domain) 	   PROCEDURE     �  CREATE PROCEDURE public.staff_insertion(IN input_name character varying, IN input_employment_period public.valid_period_domain)
    LANGUAGE plpgsql
    AS $$
DECLARE
    found BOOLEAN;
    coalesced_period valid_period_domain;
BEGIN
    -- Check if the staff already exists
    SELECT EXISTS(
        SELECT 1
        FROM "staff"
        WHERE "staff"."name" = input_name
        AND temporal_can_merge("staff"."employment_period", input_employment_period)
    ) INTO found;

    IF found THEN
        -- Insert the new period
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, input_employment_period);

        -- Get coalesced period
        WITH "temp_table" AS (
            SELECT temporal_coalesce_single("staff"."employment_period") AS "period"
            FROM "staff"
            WHERE "staff"."name" = input_name
            AND temporal_can_merge("staff"."employment_period", input_employment_period)
        )
        SELECT ("temp_table"."period").start_timestamp, ("temp_table"."period").end_timestamp
        INTO coalesced_period
        FROM "temp_table";

        -- Delete all the periods that overlap with the new one
        DELETE FROM "staff"
        WHERE "staff"."name" = input_name
        AND temporal_can_merge("staff"."employment_period", input_employment_period);

        -- Insert the new period
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, coalesced_period);
    ELSE
        -- If the staff does not exist, insert it
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, input_employment_period);
    END IF;

    -- Commit the transaction
    COMMIT;
END;
$$;
    DROP PROCEDURE public.staff_insertion(IN input_name character varying, IN input_employment_period public.valid_period_domain);
       public          anca    false    3    856            �            1255    16436 A   staff_modification(character varying, public.valid_period_domain) 	   PROCEDURE     r  CREATE PROCEDURE public.staff_modification(IN input_name character varying, IN input_employment_period public.valid_period_domain)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Call the deletion and insertion procedures
    CALL staff_deletion(input_name);
    CALL staff_insertion(input_name, input_employment_period);

    -- Commit the transaction
    COMMIT;
END;
$$;
 �   DROP PROCEDURE public.staff_modification(IN input_name character varying, IN input_employment_period public.valid_period_domain);
       public          anca    false    856    3            �            1255    16392 K   temporal_after_than(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_after_than(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp > p2.end_timestamp + 1;
END;
$$;
 h   DROP FUNCTION public.temporal_after_than(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    3    856            �            1255    16391 L   temporal_before_than(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_before_than(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.end_timestamp + 1 < p2.start_timestamp;
END;
$$;
 i   DROP FUNCTION public.temporal_before_than(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    3    856            �            1255    16406 N   temporal_can_intersect(public.valid_period_domain, public.valid_period_domain)    FUNCTION     M  CREATE FUNCTION public.temporal_can_intersect(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN NOT temporal_before_than(p1, p2)
    AND NOT temporal_after_than(p1, p2)
    AND NOT temporal_meets(p1, p2)
    AND NOT temporal_meets_inverse(p1, p2);
END;
$$;
 k   DROP FUNCTION public.temporal_can_intersect(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16404 J   temporal_can_merge(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_can_merge(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN NOT temporal_before_than(p1, p2) AND NOT temporal_after_than(p1, p2);
END;
$$;
 g   DROP FUNCTION public.temporal_can_merge(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16408 K   temporal_difference(public.valid_period_domain, public.valid_period_domain)    FUNCTION     h  CREATE FUNCTION public.temporal_difference(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS public.valid_period_domain[]
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF temporal_can_intersect(p1, p2) THEN
        IF temporal_overlaps(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain];
        ELSIF temporal_overlaps_inverse(p1, p2) THEN
            RETURN ARRAY[(p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_starts_inverse(p1, p2) THEN
            RETURN ARRAY[(p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_during_inverse(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain, (p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_finishes_inverse(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain];
        ELSE
            RETURN ARRAY[]::valid_period_domain[];
        END IF;
    ELSE
        RETURN ARRAY[p1];
    END IF;
END;
$$;
 h   DROP FUNCTION public.temporal_difference(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3    856            �            1255    16399 G   temporal_during(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_during(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;
 d   DROP FUNCTION public.temporal_during(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16400 O   temporal_during_inverse(public.valid_period_domain, public.valid_period_domain)    FUNCTION       CREATE FUNCTION public.temporal_during_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;
 l   DROP FUNCTION public.temporal_during_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16403 F   temporal_equal(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_equal(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;
 c   DROP FUNCTION public.temporal_equal(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16401 I   temporal_finishes(public.valid_period_domain, public.valid_period_domain)    FUNCTION       CREATE FUNCTION public.temporal_finishes(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;
 f   DROP FUNCTION public.temporal_finishes(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16402 Q   temporal_finishes_inverse(public.valid_period_domain, public.valid_period_domain)    FUNCTION     	  CREATE FUNCTION public.temporal_finishes_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;
 n   DROP FUNCTION public.temporal_finishes_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16438 W   temporal_intersect_to_array(public.valid_period_domain[], public.valid_period_domain[])    FUNCTION     �  CREATE FUNCTION public.temporal_intersect_to_array(parr public.valid_period_domain[], parrnew public.valid_period_domain[]) RETURNS public.valid_period_domain[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pArrResult valid_period_domain[] = '{}';
    pIter valid_period_domain;
BEGIN
    -- If the current array is empty, return the new period
    IF pArr IS NULL THEN
        RETURN pArrNew;
    END IF;

    -- Intersect the new periods with the current ones
    FOREACH pIter IN ARRAY pArrNew LOOP
        pArrResult := pArrResult || temporal_intersect_to_array(pArr, pIter);
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;
 {   DROP FUNCTION public.temporal_intersect_to_array(parr public.valid_period_domain[], parrnew public.valid_period_domain[]);
       public          anca    false    856    3            �            1255    16437 U   temporal_intersect_to_array(public.valid_period_domain[], public.valid_period_domain)    FUNCTION     �  CREATE FUNCTION public.temporal_intersect_to_array(parr public.valid_period_domain[], pnew public.valid_period_domain) RETURNS public.valid_period_domain[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pArrResult valid_period_domain[] := '{}';
    pIter valid_period_domain;
BEGIN
    -- If the current array is empty, return the new period
    IF pArr IS NULL THEN
        RETURN ARRAY[pNew];
    END IF;

    FOREACH pIter IN ARRAY pArr LOOP
        -- If the new period can be intersected with the current one, intersect them
        IF temporal_can_intersect(pIter, pNew) THEN
            pArrResult := pArrResult || temporal_intersection(pIter, pNew);
        END IF;
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;
 v   DROP FUNCTION public.temporal_intersect_to_array(parr public.valid_period_domain[], pnew public.valid_period_domain);
       public          anca    false    856    856    3            �            1255    16407 M   temporal_intersection(public.valid_period_domain, public.valid_period_domain)    FUNCTION     ;  CREATE FUNCTION public.temporal_intersection(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS public.valid_period_domain
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (GREATEST(p1.start_timestamp, p2.start_timestamp), LEAST(p1.end_timestamp, p2.end_timestamp))::valid_period_domain;
END;
$$;
 j   DROP FUNCTION public.temporal_intersection(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    3    856            �            1255    16393 F   temporal_meets(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_meets(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.end_timestamp + 1 = p2.start_timestamp;
END;
$$;
 c   DROP FUNCTION public.temporal_meets(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16394 N   temporal_meets_inverse(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_meets_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp = p2.end_timestamp + 1;
END;
$$;
 k   DROP FUNCTION public.temporal_meets_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16405 F   temporal_merge(public.valid_period_domain, public.valid_period_domain)    FUNCTION     4  CREATE FUNCTION public.temporal_merge(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS public.valid_period_domain
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (LEAST(p1.start_timestamp, p2.start_timestamp), GREATEST(p1.end_timestamp, p2.end_timestamp))::valid_period_domain;
END;
$$;
 c   DROP FUNCTION public.temporal_merge(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16410 S   temporal_merge_to_array(public.valid_period_domain[], public.valid_period_domain[])    FUNCTION     0  CREATE FUNCTION public.temporal_merge_to_array(parr public.valid_period_domain[], parrnew public.valid_period_domain[]) RETURNS public.valid_period_domain[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pArrResult valid_period_domain[];
    pIter valid_period_domain;
BEGIN
    -- Initialize the result array
    pArrResult := pArr;

    -- Merge the new periods with the current ones
    FOREACH pIter IN ARRAY pArrNew LOOP
        pArrResult := temporal_merge_to_array(pArrResult, pIter);
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;
 w   DROP FUNCTION public.temporal_merge_to_array(parr public.valid_period_domain[], parrnew public.valid_period_domain[]);
       public          anca    false    856    3            �            1255    16409 Q   temporal_merge_to_array(public.valid_period_domain[], public.valid_period_domain)    FUNCTION     �  CREATE FUNCTION public.temporal_merge_to_array(parr public.valid_period_domain[], pnew public.valid_period_domain) RETURNS public.valid_period_domain[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    pArrResult valid_period_domain[] := '{}';
    pIter valid_period_domain;
BEGIN
    FOREACH pIter IN ARRAY pArr LOOP
        -- If the new period can be merged with the current one, merge them
        IF temporal_can_merge(pIter, pNew) THEN
            pNew := temporal_merge(pIter, pNew);
        ELSE -- If not, append the current period to the result
            pArrResult := pArrResult || pIter;
        END IF;
    END LOOP;

    -- Append the new period to the result
    RETURN pArrResult || pNew;
END;
$$;
 r   DROP FUNCTION public.temporal_merge_to_array(parr public.valid_period_domain[], pnew public.valid_period_domain);
       public          anca    false    856    3    856            �            1255    16395 I   temporal_overlaps(public.valid_period_domain, public.valid_period_domain)    FUNCTION     ,  CREATE FUNCTION public.temporal_overlaps(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp AND p1.end_timestamp >= p2.start_timestamp;
END;
$$;
 f   DROP FUNCTION public.temporal_overlaps(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16396 Q   temporal_overlaps_inverse(public.valid_period_domain, public.valid_period_domain)    FUNCTION     4  CREATE FUNCTION public.temporal_overlaps_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp AND p1.start_timestamp <= p2.end_timestamp;
END;
$$;
 n   DROP FUNCTION public.temporal_overlaps_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16414 2   temporal_slice(public.valid_period_domain, bigint)    FUNCTION     �   CREATE FUNCTION public.temporal_slice(p public.valid_period_domain, input_timestamp bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p.start_timestamp <= input_timestamp AND p.end_timestamp >= input_timestamp;
END;
$$;
 [   DROP FUNCTION public.temporal_slice(p public.valid_period_domain, input_timestamp bigint);
       public          anca    false    856    3            �            1255    16397 G   temporal_starts(public.valid_period_domain, public.valid_period_domain)    FUNCTION     �   CREATE FUNCTION public.temporal_starts(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;
 d   DROP FUNCTION public.temporal_starts(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            �            1255    16398 O   temporal_starts_inverse(public.valid_period_domain, public.valid_period_domain)    FUNCTION       CREATE FUNCTION public.temporal_starts_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;
 l   DROP FUNCTION public.temporal_starts_inverse(p1 public.valid_period_domain, p2 public.valid_period_domain);
       public          anca    false    856    3            h           1255    16413 8   temporal_coalesce_multiple(public.valid_period_domain[]) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_coalesce_multiple(public.valid_period_domain[]) (
    SFUNC = public.temporal_merge_to_array,
    STYPE = public.valid_period_domain[],
    INITCOND = '{}'
);
 P   DROP AGGREGATE public.temporal_coalesce_multiple(public.valid_period_domain[]);
       public          anca    false    244    856    3            g           1255    16412 6   temporal_coalesce_multiple(public.valid_period_domain) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_coalesce_multiple(public.valid_period_domain) (
    SFUNC = public.temporal_merge_to_array,
    STYPE = public.valid_period_domain[],
    INITCOND = '{}'
);
 N   DROP AGGREGATE public.temporal_coalesce_multiple(public.valid_period_domain);
       public          anca    false    3    856    856    243            f           1255    16411 4   temporal_coalesce_single(public.valid_period_domain) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_coalesce_single(public.valid_period_domain) (
    SFUNC = public.temporal_merge,
    STYPE = public.valid_period_domain
);
 L   DROP AGGREGATE public.temporal_coalesce_single(public.valid_period_domain);
       public          anca    false    3    856    226            e           1255    16441 7   temporal_section_multiple(public.valid_period_domain[]) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_section_multiple(public.valid_period_domain[]) (
    SFUNC = public.temporal_intersect_to_array,
    STYPE = public.valid_period_domain[]
);
 O   DROP AGGREGATE public.temporal_section_multiple(public.valid_period_domain[]);
       public          anca    false    3    230    856            d           1255    16440 5   temporal_section_multiple(public.valid_period_domain) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_section_multiple(public.valid_period_domain) (
    SFUNC = public.temporal_intersect_to_array,
    STYPE = public.valid_period_domain[]
);
 M   DROP AGGREGATE public.temporal_section_multiple(public.valid_period_domain);
       public          anca    false    3    856    856    229            c           1255    16439 3   temporal_section_single(public.valid_period_domain) 	   AGGREGATE     �   CREATE AGGREGATE public.temporal_section_single(public.valid_period_domain) (
    SFUNC = public.temporal_intersection,
    STYPE = public.valid_period_domain
);
 K   DROP AGGREGATE public.temporal_section_single(public.valid_period_domain);
       public          anca    false    856    228    3            �            1259    16415    customer    TABLE     �   CREATE TABLE public.customer (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    subscription_period public.valid_period_domain NOT NULL
);
    DROP TABLE public.customer;
       public         heap    anca    false    3    856            �            1259    16423    staff    TABLE     �   CREATE TABLE public.staff (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    employment_period public.valid_period_domain NOT NULL
);
    DROP TABLE public.staff;
       public         heap    anca    false    856    3            ;          0    16415    customer 
   TABLE DATA           A   COPY public.customer (id, name, subscription_period) FROM stdin;
    public          anca    false    210   �n       <          0    16423    staff 
   TABLE DATA           <   COPY public.staff (id, name, employment_period) FROM stdin;
    public          anca    false    211   �o       �           2606    16422    customer customer_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.customer DROP CONSTRAINT customer_pkey;
       public            anca    false    210            �           2606    16430    staff staff_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_pkey;
       public            anca    false    211            ;   �   x�5��J1Eם/�i�4m��;�ܤi�{#��G��=�s;�E�
�� �`ta	��+�>N;ӎ�6ĥ$�����	zC����Y����65,�R!��-t1�⁑�����-�r�K�x����*�֬�I��o�T{�ֲ G�C����,�;���v:�*Rʎ�@Z�u�&�ޤ���,+����� �O۶}O�H�      <   �   x�=�An!�5�$#�+c������`�n��R��Y� Oϥ��Or�MȒ�0��w3TM�v����zr:bqjƤ�R틠�XYt$���G��f�x/'��d5�
�b�Pzx��g������L`��.1뼮$�uռ�έ�_�S����1��13f     