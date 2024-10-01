from pyenergyplus.plugin import EnergyPlusPlugin

class AverageZoneTemps(EnergyPlusPlugin):

    def __init__(self):
        super().__init__()
        self.do_setup = True

    def on_end_of_zone_timestep_before_zone_reporting(self, state) -> int:
        if self.do_setup:
            self.data['zone_volumes'] = []
            self.data['zone_temps'] = []
            zone_names = ["Story 1 Core Thermal Zone", "Story 1 East Perimeter Thermal Zone", "Story 1 North Perimeter Thermal Zone", "Story 1 South Perimeter Thermal Zone", "Story 1 West Perimeter Thermal Zone"]
            for zone_name in zone_names:
                handle = self.api.exchange.get_internal_variable_handle(state, 'Zone Air Volume', zone_name)
                zone_volume = self.api.exchange.get_internal_variable_value(state, handle)
                self.data['zone_volumes'].append(zone_volume)
                self.data['zone_temps'].append(
                    self.api.exchange.get_variable_handle(state, 'Zone Mean Air Temperature', zone_name)
                )
            self.data['avg_temp_variable'] = self.api.exchange.get_global_handle(state, 'AverageBuildingTemp')
            self.data['trend'] = self.api.exchange.get_trend_handle(state, 'Running Averaged Building Temperature')
            self.data['running_avg_temp_variable'] = self.api.exchange.get_global_handle(state, 'RunningAverageBuildingTemp')
            self.do_setup = False
        zone_temps = list()
        for t_handle in self.data['zone_temps']:
            zone_temps.append(self.api.exchange.get_variable_value(state, t_handle))
        numerator = 0.0
        denominator = 0.0
        for i in range(len(self.data['zone_volumes'])):
            numerator += self.data['zone_volumes'][i] * zone_temps[i]
            denominator += self.data['zone_volumes'][i]
        average_temp = numerator / denominator
        self.api.exchange.set_global_value(state, self.data['avg_temp_variable'], average_temp)

        past_daily_avg_temp = self.api.exchange.get_trend_average(state, self.data['trend'], 96)
        self.api.exchange.set_global_value(state, self.data['running_avg_temp_variable'], past_daily_avg_temp)
        return 0
