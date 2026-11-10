function postprocess(df::DataFrame, vars::DataFrame; nt::Int=5)

    ids = [:year, :imputation, :hid]

    # Rename explicit variables (varkey → varname)
    explicit_vars = vars[coalesce.(vars.type, "") .!= "prefix", :]
    rename_dict   = Dict(Symbol(row.varkey) => Symbol(row.varname)
                         for row in eachrow(explicit_vars) if row.varkey != row.varname)
    rename!(df, rename_dict)

    # Collect prefix-matched column names (kept with their original names)
    prefix_keys = collect(vars[coalesce.(vars.type, "") .== "prefix", :varkey])
    prefix_cols = filter(col -> any(startswith(col, p) for p in prefix_keys), names(df))

    # Keep only requested columns (ids + explicit varnames + prefix-matched)
    keep_cols = unique([string.(ids); string.(explicit_vars.varname); prefix_cols])
    keep_cols = filter(col -> col in names(df), keep_cols)
    select!(df, keep_cols)

    # Type conversions — non-numeric HFCS codes (e.g. "A" = not applicable) become missing
    _to_float(x) = ismissing(x) ? missing :
                   x isa Number ? Float64(x) :
                   something(tryparse(Float64, strip(string(x))), missing)
    df[!, :wlth]  = _to_float.(df.wlth)
    df[!, :di2000] = _to_float.(df.di2000)

    # Additional variables
    year_int = df.year[1]
    _b(x) = coalesce(x, false)   # treat missing as false in boolean conditions
    _v(x) = Float64(coalesce(x, 0))  # treat missing as 0 in value accumulation

    # Age by 10-year bins
    df[!, :edad10] = passmissing(x -> Int(10 * floor((x - 5) / 10) + 5)).(df.edad)

    # Labor income, capital income, total income (NA treated as 0, as in R's rowSums)
    df[!, :incL] = @. coalesce(df.di1100, 0) + coalesce(df.di1200, 0)
    df[!, :incK] = @. coalesce(df.hg0310, 0) + coalesce(df.hg0410, 0) + coalesce(df.hg0510, 0)
    df[!, :incT] = @. df.incL + df.incK + coalesce(df.pens, 0)

    # Bequests: value if transfer was (1) a bequest, (2) from parents, (3) in last nt years
    df[!, :her1] = @. ifelse(_b(df.hh0501==2) & _b(df.hh0601==3) & _b(df.hh0201 > year_int-nt), _v(df.hh0401), 0.0)
    df[!, :her2] = @. ifelse(_b(df.hh0502==2) & _b(df.hh0602==3) & _b(df.hh0202 > year_int-nt), _v(df.hh0402), 0.0)
    df[!, :her3] = @. ifelse(_b(df.hh0503==2) & _b(df.hh0603==3) & _b(df.hh0203 > year_int-nt), _v(df.hh0403), 0.0)
    df[!, :herT] = @. df.her1 + df.her2 + df.her3

    # Gifts: value if transfer was (1) a gift, (2) from parents, (3) in last nt years
    df[!, :don1] = @. ifelse(_b(df.hh0501==1) & _b(df.hh0601==3) & _b(df.hh0201 > year_int-nt), _v(df.hh0401), 0.0)
    df[!, :don2] = @. ifelse(_b(df.hh0502==1) & _b(df.hh0602==3) & _b(df.hh0202 > year_int-nt), _v(df.hh0402), 0.0)
    df[!, :don3] = @. ifelse(_b(df.hh0503==1) & _b(df.hh0603==3) & _b(df.hh0203 > year_int-nt), _v(df.hh0403), 0.0)
    df[!, :donT] = @. df.don1 + df.don2 + df.don3

    # Remove Missing type from columns that contain no missing values
    for col in names(df)
        if !any(ismissing, df[!, col])
            df[!, col] = disallowmissing(df[!, col])
        end
    end

    sort!(df, ids)
    return df
end


function read_hfcs(
    datadir::String,
    identifier_ranges;
    nt::Int=5,
    varlists_dir::String=joinpath(BASE_FOLDER, "var_lists"),
    varlist_filename::String="hfcs_vars.csv",
    kwargs...
)
    # Normalize: scalars must be wrapped in a vector for read_database
    _wrap(v) = v isa AbstractVector ? v : [v]
    normalized = Tuple(p.first => _wrap(p.second) for p in identifier_ranges)
    _post(df, vars) = postprocess(df, vars; nt)
    return read_database(
        datadir, normalized, get_household_id_var;
        varlists_dir, varlist_filename,
        filefinder, postprocess=_post,
        makeunique=true, do_rename=false, get_select_fn,
        kwargs...
    )
end
