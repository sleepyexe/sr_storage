return {
    ['delperro'] = {
        label = 'Del Perro Warehouse',
        weight = 100, -- 100 = 100kg
        slots = 100, -- inventory slot
        payment = 10000, -- first time buy,
        daily = 5000, -- daily pay,
        zones = {
            {
                blip = true,
                name = "Del Pero",
                coords = vec3(-1607.0, -829.55, 10.6),
                size = vec3(3.5, 2.6, 1.65),
                rotation = 318.75,
            },
            {
                name = "Delpero 2",
                coords = vec3(-1611.75, -826.36, 10.0),
                size = vec3(3.5, 2.6, 1.65),
                rotation = 318.75,
            },
        }
    }
}