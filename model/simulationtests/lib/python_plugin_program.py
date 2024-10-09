from pyenergyplus.plugin import EnergyPlusPlugin

import os, sys
sys.path.append('C:/Python38/Lib/site-packages') # this should (needs to?) be same version as E+'s version
import pandas as pd

class <%= pluginClassName %>(EnergyPlusPlugin):

    def __init__(self):
        super().__init__()
        self.do_setup = True

        self.df = pd.read_csv(os.path.join(os.path.dirname(__file__), 'python_plugin_program.csv'))

    def on_end_of_zone_timestep_before_zone_reporting(self, state) -> int:
        if self.do_setup:
            self.data['zone_volumes'] = []
            self.data['zone_temps'] = []
            zone_names = <%= model.getThermalZones.map(&:nameString).sort %>
            for zone_name in zone_names:
                handle = self.api.exchange.get_internal_variable_handle(state, 'Zone Air Volume', zone_name)
                zone_volume = self.api.exchange.get_internal_variable_value(state, handle)
                self.data['zone_volumes'].append(zone_volume)
                self.data['zone_temps'].append(
                    self.api.exchange.get_variable_handle(state, 'Zone Mean Air Temperature', zone_name)
                )
            self.data['avg_temp_variable'] = self.api.exchange.get_global_handle(state, '<%= py_var.nameString %>')
            self.data['trend'] = self.api.exchange.get_trend_handle(state, '<%= py_trend_var.nameString %>')
            self.data['running_avg_temp_variable'] = self.api.exchange.get_global_handle(state, '<%= py_var2.nameString %>')
            self.do_setup = False
        zone_temps = list()
        for t_handle in self.data['zone_temps']:
            zone_temps.append(self.api.exchange.get_variable_value(state, t_handle))
        numerator = float(self.df.iloc[0]['numerator'])
        denominator = float(self.df.iloc[0]['denominator'])
        for i in range(len(self.data['zone_volumes'])):
            numerator += self.data['zone_volumes'][i] * zone_temps[i]
            denominator += self.data['zone_volumes'][i]
        average_temp = numerator / denominator
        self.api.exchange.set_global_value(state, self.data['avg_temp_variable'], average_temp)

        past_daily_avg_temp = self.api.exchange.get_trend_average(state, self.data['trend'], 96)
        self.api.exchange.set_global_value(state, self.data['running_avg_temp_variable'], past_daily_avg_temp)
        return 0
