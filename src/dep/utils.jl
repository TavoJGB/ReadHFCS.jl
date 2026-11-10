# One observation row per (year, imputation, household): join key is "id"
get_household_id_var(; kwargs...) = "id"

# Three CSV files per (year, imputation): household core (h), non-core (hn), derived (d)
filefinder(dir::String; year::Int, imputation::Int, kwargs...) = [
    joinpath(dir, "HFCS_$(year)", "h$(imputation).csv"),
    joinpath(dir, "HFCS_$(year)", "hn$(imputation).csv"),
    joinpath(dir, "HFCS_$(year)", "d$(imputation).csv"),
]

# Column selector: loads exact varkeys plus any column whose name starts with a
# "prefix"-typed varkey (used for the positional range hb1201a:hb1301 in the R code).
function get_select_fn(vars)
    explicit_keys = Set(vars[coalesce.(vars.type, "") .!= "prefix", :varkey])
    prefix_keys   = collect(vars[coalesce.(vars.type, "") .== "prefix", :varkey])
    return (_, name) -> begin
        sname = String(name)
        return sname in explicit_keys || any(startswith(sname, p) for p in prefix_keys)
    end
end

# Panel helpers
get_prev_year(year::Int) = get(HFCS_PREV_YEAR, year, nothing)
get_wave_gap(year::Int) = get(HFCS_WAVE_GAP, year, nothing)