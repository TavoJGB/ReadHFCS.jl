const HFCS_WAVES = [2010; 2014; 2017; 2021; 2023]
const HFCS_WAVE_GAP = Dict(HFCS_WAVES[2:end] .=> diff(HFCS_WAVES))
const HFCS_PREV_YEAR = Dict(HFCS_WAVES[2:end] .=> HFCS_WAVES[1:(end-1)])