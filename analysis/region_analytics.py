# -*- coding: utf-8 -*-
"""
Created on Sat Jan 22 00:23:47 2022

@author: Danielle Lambion
"""
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from scipy import stats

import plotly.express as px
import plotly.graph_objects as go
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score

def compute_regression_corr(arr1, arr2):
    corr_matrix = np.corrcoef(arr1, arr2)
    r_squared = corr_matrix[0,1]**2
    return r_squared

def compute_corr_coef(arr1, arr2):
    return stats.pearsonr(arr1, arr2)

def calculate_function_cpusteal_corr(df):
    print("R-squared between CPU steal and function 1 runtime:",
          compute_regression_corr(df['runtime function1 (ms)'], df['vmcpustealDelta/min function1']))
    print("R-squared between CPU steal and function 2 runtime:",
          compute_regression_corr(df['runtime function2 (ms)'], df['vmcpustealDelta/min function2']))
    print("R-squared between CPU steal and function 3 runtime:",
          compute_regression_corr(df['runtime function3 (ms)'], df['vmcpustealDelta/min function3']))
    
# =============================================================================
# def calculate_region_corr(df_eu_central, df_us_east, df_ap_ne):
#     print("R-squared between eu-central-1 and us-east-2:",
#           compute_regression_corr(df_eu_central['total runtime (ms)'], df_us_east['total runtime (ms)']))
#     print("R-squared between eu-central-1 and ap-northeast-1:",
#           compute_regression_corr(df_eu_central['total runtime (ms)'], df_ap_ne['total runtime (ms)']))
#     print("R-squared between us-east-2 and ap-northeast-1:",
#           compute_regression_corr(df_us_east['total runtime (ms)'], df_ap_ne['total runtime (ms)']))
# =============================================================================
    
def calculate_workflow_cpusteal_corr(df_eu_central, df_us_east, df_ap_ne, df_us_west):
    print("Computed with CPU Steal/Min:\n")
    print("R-squared between normalized CPU steal and run time for eu-central-1:",
          compute_regression_corr(df_eu_central['total runtime (ms)'], df_eu_central['total vmcpustealDelta/min']))
    print("Pearson correlation between normalized CPU steal and run time for eu-central-1:",
          compute_corr_coef(df_eu_central['total runtime (ms)'], df_eu_central['total vmcpustealDelta/min']))
    
    print("R-squared between normalized CPU steal and run time for ap-northeast-1:",
          compute_regression_corr(df_ap_ne['total runtime (ms)'], df_ap_ne['total vmcpustealDelta/min']))
    print("Pearson correlation between normalized CPU steal and run time for ap-northeast-1:",
          compute_corr_coef(df_ap_ne['total runtime (ms)'], df_ap_ne['total vmcpustealDelta/min']))
    
    print("R-squared between normalized CPU steal and run time for  us-east-2:",
          compute_regression_corr(df_us_east['total runtime (ms)'], df_us_east['total vmcpustealDelta/min']))
    print("Pearson correlation between normalized CPU steal and run time for  us-east-2:",
          compute_corr_coef(df_us_east['total runtime (ms)'], df_us_east['total vmcpustealDelta/min']))
    
    print("R-squared between normalized CPU steal and run time for  us-west-2:",
          compute_regression_corr(df_us_west['total runtime (ms)'], df_us_west['total vmcpustealDelta/min']))
    print("Pearson correlation between normalized CPU steal and run time for  us-west-2:",
          compute_corr_coef(df_us_west['total runtime (ms)'], df_us_west['total vmcpustealDelta/min']))
    
    print("\nComputed with CPU Steal:\n")
    print("R-squared between CPU steal and run time for eu-central-1:",
          compute_regression_corr(df_eu_central['total runtime (ms)'], df_eu_central['total vmcpustealDelta']))
    print("R-squared between CPU steal and run time for ap-northeast-1:",
          compute_regression_corr(df_ap_ne['total runtime (ms)'], df_ap_ne['total vmcpustealDelta']))
    print("R-squared between CPU steal and run time for  us-east-2:",
          compute_regression_corr(df_us_east['total runtime (ms)'], df_us_east['total vmcpustealDelta']))
    print("R-squared between CPU steal and run time for  us-west-2:",
          compute_regression_corr(df_us_west['total runtime (ms)'], df_us_west['total vmcpustealDelta']))
    
def calculate_region_function_cpusteal_corr(df_eu_central, df_us_east, df_ap_ne, function):
    if function == 3:
        print("R-squared between CPU steal and run time for eu-central-1:",
              compute_regression_corr(df_eu_central['runtime function3 (ms)'], df_eu_central['vmcpustealDelta/min function3']))
        print("R-squared between CPU steal and run time for ap-northeast-1:",
              compute_regression_corr(df_ap_ne['runtime function3 (ms)'], df_ap_ne['vmcpustealDelta/min function3']))
        print("R-squared between CPU steal and run time for  us-east-2:",
              compute_regression_corr(df_us_east['runtime function3 (ms)'], df_us_east['vmcpustealDelta/min function3']))
    elif function == 2:
        print("R-squared between CPU steal and run time for eu-central-1:",
              compute_regression_corr(df_eu_central['runtime function2 (ms)'], df_eu_central['vmcpustealDelta/min function2']))
        print("R-squared between CPU steal and run time for ap-northeast-1:",
              compute_regression_corr(df_ap_ne['runtime function2 (ms)'], df_ap_ne['vmcpustealDelta/min function2']))
        print("R-squared between CPU steal and run time for  us-east-2:",
              compute_regression_corr(df_us_east['runtime function2 (ms)'], df_us_east['vmcpustealDelta/min function2']))
    else:
        print("R-squared between CPU steal and run time for eu-central-1:",
              compute_regression_corr(df_eu_central['runtime function1 (ms)'], df_eu_central['vmcpustealDelta/min function1']))
        print("R-squared between CPU steal and run time for ap-northeast-1:",
              compute_regression_corr(df_ap_ne['runtime function1 (ms)'], df_ap_ne['vmcpustealDelta/min function1']))
        print("R-squared between CPU steal and run time for us-east-2:",
              compute_regression_corr(df_us_east['runtime function1 (ms)'], df_us_east['vmcpustealDelta/min function1']))

def calculate_stats(df, global_arch_avg=0):
    sd = df['total runtime (ms)'].std()
    avg = df['total runtime (ms)'].mean()
    print("Min runtime:", df['total runtime (ms)'].min())
    print("Max runtime:", df['total runtime (ms)'].max())
    print("Average runtime:", avg)
    print("Standard deviation of runtime:", sd)
    print("Coefficient of variation of runtime:", sd/avg)
    print("Average CPU Steal/Min:", df['total vmcpustealDelta/min'].mean())
    if global_arch_avg > 0:
        if global_arch_avg > avg:
            diff = global_arch_avg / avg
            print('Region is faster than global average runtime by',
                  (diff-1)*100, '%')
        elif global_arch_avg < avg:
            diff = avg / global_arch_avg
            print('Region is slower than global average runtime by',
                  (diff-1)*100, '%')
        elif global_arch_avg == avg:
                print("0% difference")
    print('\n')
    print("Coefficient of variation of function 1:",
          df['runtime function1 (ms)'].std()/df['runtime function1 (ms)'].mean())
    print("Coefficient of variation of function 2:",
          df['runtime function2 (ms)'].std()/df['runtime function2 (ms)'].mean())
    print("Coefficient of variation of function 3:",
          df['runtime function3 (ms)'].std()/df['runtime function3 (ms)'].mean())

def welchs_ttest(var1, var2):
    print(stats.ttest_ind(var1, var2, equal_var = False)[1])

def convert_to_hour(timedate):
    hour = int(timedate[11:13])
    if(hour < 2):
        return '0-1:59'
    elif(hour >= 2 and hour < 4):
        return '2-3:59'
    elif(hour >= 4 and hour < 6):
        return '4-5:59'
    elif(hour >= 6 and hour < 8):
        return '6-7:59'
    elif(hour >= 8 and hour < 10):
        return '8-9:59'
    elif(hour >= 10 and hour < 12):
        return '10-11:59'
    elif(hour >= 12 and hour < 14):
        return '12-13:59'
    elif(hour >= 14 and hour < 16):
        return '14-15:59'
    elif(hour >= 16 and hour < 18):
        return '16-17:59'
    elif(hour >= 18 and hour < 20):
        return '18-19:59'
    elif(hour >= 20 and hour < 22):
        return '20-21:59'
    elif(hour >= 22 and hour < 24):
        return '22-23:59'
    
def block_averages(df, block_hour=2):
    print(int(df.iloc[0]['start time'][11:13]))

def region_rename(region):
    if region == 'ap-northeast-1':
        return 'Asia'
    elif region == 'eu-central-1':
        return 'Europe'
    elif region == 'us-east-2':
        return 'US East'
    else:
        return 'US West'
    
def linear_regr(df, name):
    # Create linear regression object
    regr = LinearRegression()
    df['total runtime (ms)'] = df['total runtime (ms)'].apply(lambda x: x/1000)
    df['region'] = df['region'].apply(lambda x: region_rename(x))
    X = df['total vmcpustealDelta/min'].values.reshape(-1, 1)
    # Train the model using the training sets
    regr.fit(X, df['total runtime (ms)'])
    
    # Make predictions using the testing set
    #diabetes_y_pred = regr.predict(diabetes_X_test)
    df.rename(columns = {'total runtime (ms)':'Pipeline Runtime (s)'}, inplace = True)
    df.rename(columns = {'total vmcpustealDelta/min':'CPU Steal per Minute'}, inplace = True)
    df.rename(columns = {'region':'Region'}, inplace = True)
    # The coefficients
    #print("Coefficients: \n", regr.coef_)
    x_range = np.linspace(X.min(), X.max(), 100)
    y_range = regr.predict(x_range.reshape(-1, 1))
    #print('xrange',x_range)
    colorPallet = ["rgba(151, 209, 233, 255)", "rgba(0, 120, 179, 255)",
                   "rgba(179, 223, 146, 255)", "rgba(49, 169, 90, 255)"]#, "rgba(227, 136, 220, 255)", "rgba(127, 0, 255, 255)", "rgba(255, 128, 0, 255)"]
    color_discrete_map = {'Asia': "rgba(151, 209, 233, 255)", 'Europe': "rgba(0, 120, 179, 255)",
                          'US East': "rgba(179, 223, 146, 255)", 'US West':"rgba(49, 169, 90, 255)" }
    fig = px.scatter(df, x='Pipeline Runtime (s)', y='CPU Steal per Minute',# opacity=0.65,
                     color = "Region", color_discrete_map=color_discrete_map)
# =============================================================================
#     fig.update_layout(legend=dict(
#         orientation="h",
#         yanchor="bottom",
#         y=1.02,
#         xanchor="right",
#         x=1),
#         plot_bgcolor='rgba(245,245,255,255)'
#     )
# =============================================================================
    fig.update_layout(
    barmode='stack',
    legend=dict(
        orientation="h",
        yanchor="bottom",
        y=1.02,
        xanchor="center",
        x=0.47
    ),
    margin=dict(
        t=0,
        b=1,
        l=1,
        r=1,
        autoexpand=True
    ),
    font=dict(
        size=16
    ),
    plot_bgcolor='rgba(245,245,255,255)'
    )
    fig.update_layout(legend={'title_text':''})
    fig.add_traces(go.Scatter(x=y_range, y=x_range, name='Regression Fit'))
    fig.update_yaxes(range=[0,120])
    fig.update_xaxes(range=[590,950])
    fig.show()
    fig.write_image(name+"_runtime_cpu_steal_regression.pdf", engine="kaleido")#, width=baseFigureWidth, height=baseFigureHeight)
    
def main():
    path = 'C:/Users/Danielle/Desktop/cloudpaper/tcss562_topic_modeling/test/'
    filename = path+"20220119-results.csv"
    df = pd.read_csv(filename, sep=',')
    df = pd.read_csv(path+'results.csv')
    #print(df.region.value_counts())
    #print(df_indiv.region.value_counts())
    df_us_east_arm = df[0:112]
    df_ap_ne_arm = df[df['region'] == 'ap-northeast-1']
    df_ap_ne_arm = df_ap_ne_arm[0:112]
    df_eu_central_arm = df[df['region'] == 'eu-central-1']
    df_eu_central_arm = df_eu_central_arm[0:112]
    df_us_west_arm = df[df['region'] == 'us-west-2'][0:112]
# =============================================================================
#     print(df_eu_central_arm['arch'])
#     print(len(df_eu_central_arm))
# =============================================================================
# =============================================================================
#     print('-------------------------------------------------------------')
#     print("R-squared between regions for workflow runtime for ARM\n")
#     calculate_region_corr(df_eu_central_arm, df_us_east_arm, df_ap_ne_arm)
#     print('-------------------------------------------------------------')
# =============================================================================
    
    df_x86 = df[df['arch'] == 'x86_64']
    df_indiv_x86 = df[df['arch'] == 'x86_64']
    df_us_east_x86 = df_x86[0:112]
    df_ap_ne_x86 = df_x86[df_x86['region'] == 'ap-northeast-1'][0:112]
    df_eu_central_x86 = df_x86[df_x86['region'] == 'eu-central-1'][0:112]
    df_us_west_x86 = df_indiv_x86[df_indiv_x86['region'] == 'us-west-2'][0:112]
    #print(df_us_west_x86['start time'])
    
    print('-------------------------------------------------------------')
    print("R-squared between CPU steal time and workflow runtime for ARM\n")
    calculate_workflow_cpusteal_corr(df_eu_central_arm, df_us_east_arm, df_ap_ne_arm,
                                     df_us_west_arm)
    print('-------------------------------------------------------------')
    print("R-squared between CPU steal time and workflow runtime for x86\n")
    calculate_workflow_cpusteal_corr(df_eu_central_x86, df_us_east_x86, df_ap_ne_x86,
                                     df_us_west_x86)
    print('-------------------------------------------------------------')
    
   #print(df_indiv.columns)
    
    df_us_east_arm_indiv = df[0:112]
    df_ap_ne_arm_indiv = df[df['region'] == 'ap-northeast-1']
    df_ap_ne_arm_indiv = df_ap_ne_arm_indiv[0:112]
    df_eu_central_arm_indiv = df[df['region'] == 'eu-central-1']
    df_eu_central_arm_indiv = df_eu_central_arm_indiv[0:112]

    df_us_east_x86_indiv = df_indiv_x86[0:112]
    df_ap_ne_x86_indiv = df_indiv_x86[df_indiv_x86['region'] == 'ap-northeast-1'][0:112]
    df_eu_central_x86_indiv = df_indiv_x86[df_indiv_x86['region'] == 'eu-central-1'][0:112]
    #print(df_us_east_arm_indiv[['start time', 'arch']])
    
    #TODO: regression analysis of each function to cpu steal time(R^2)
    #compare each function cpustealtime and runtime by regression analysis
    print("R-squared between CPU steal time and function 1 runtime for x86\n")
    calculate_region_function_cpusteal_corr(df_eu_central_x86,df_us_east_x86,
                                     df_ap_ne_x86, 1)
    print('-------------------------------------------------------------')
    print("R-squared between CPU steal time and function 2 runtime for x86\n")
    calculate_region_function_cpusteal_corr(df_eu_central_x86_indiv, df_us_east_x86,
                                     df_ap_ne_x86, 2)
    print('-------------------------------------------------------------')
    print("R-squared between CPU steal time and function 3 runtime for x86\n")
    calculate_region_function_cpusteal_corr(df_eu_central_x86, df_us_east_x86,
                                     df_ap_ne_x86, 3)
    print('-------------------------------------------------------------')
    
    
    global_x86 = pd.concat([df_us_east_x86, df_ap_ne_x86, df_eu_central_x86,
                           df_us_west_x86])
    global_arm = pd.concat([df_us_east_arm, df_ap_ne_arm, df_eu_central_arm,
                           df_us_west_arm])
    
    print("R-squared between CPU steal time and runtime for x86 (all regions)\n")
    calculate_function_cpusteal_corr(df_indiv_x86)
    print("\nPearson correlation between normalized CPU steal and run time for global x86:",
          compute_corr_coef(global_x86['total runtime (ms)'], global_x86['total vmcpustealDelta/min']))
    print('-------------------------------------------------------------')

    #find avg (normalized)cpu steal time for each function, which has highest?
    
# =============================================================================
#     print(global_arm.region.value_counts())
#     print(global_arm.arch.value_counts())
# =============================================================================
    
    avg_runtime_x86 = global_x86['total runtime (ms)'].mean()
    avg_runtime_arm = global_arm['total runtime (ms)'].mean()
    
    print("Stats on global x86 data\n")
    calculate_stats(global_x86)
    print('-------------------------------------------------------------')
    print("Stats on global ARM data\n")
    calculate_stats(global_arm)
    print('-------------------------------------------------------------')
    print("Stats on x86 us-east-2\n")
    calculate_stats(df_us_east_x86, avg_runtime_x86)
    print('-------------------------------------------------------------')
    print("Stats on x86 us-west-2\n")
    calculate_stats(df_us_west_x86, avg_runtime_x86)
    print('-------------------------------------------------------------')
    print("Stats on x86 eu-central-1\n")
    calculate_stats(df_eu_central_x86, avg_runtime_x86)
    print('-------------------------------------------------------------')
    print("Stats on x86 ap-northeast-1\n")
    calculate_stats(df_ap_ne_x86, avg_runtime_x86)
    print('-------------------------------------------------------------')
    
    print("Stats on ARM us-east-2\n")
    calculate_stats(df_us_east_arm, avg_runtime_arm)
    print('-------------------------------------------------------------')
    print("Stats on ARM us-west-2\n")
    calculate_stats(df_us_west_arm, avg_runtime_arm)
    print('-------------------------------------------------------------')
    print("Stats on ARM eu-central-1\n")
    calculate_stats(df_eu_central_arm, avg_runtime_arm)
    print('-------------------------------------------------------------')
    print("Stats on ARM ap-northeast-1\n")
    calculate_stats(df_ap_ne_arm, avg_runtime_arm)
    print('-------------------------------------------------------------')
    
    # WELCH'S T-TEST for x86
    print("Welch's t-test on x86 us-east-2 against all x86\n")
    welchs_ttest(df_us_east_x86['total runtime (ms)'], global_x86['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on x86 us-west-2\n")
    welchs_ttest(df_us_west_x86['total runtime (ms)'], global_x86['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on x86 eu-central-1\n")
    welchs_ttest(df_eu_central_x86['total runtime (ms)'], global_x86['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on x86 ap-northeast-1\n")
    welchs_ttest(df_ap_ne_x86['total runtime (ms)'], global_x86['total runtime (ms)'])
    print('-------------------------------------------------------------')
    
    # WELCH's T-TESTS for ARM
    print("Welch's t-test on ARM us-east-2\n")
    welchs_ttest(df_us_east_arm['total runtime (ms)'], global_arm['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on ARM us-west-2\n")
    welchs_ttest(df_us_west_arm['total runtime (ms)'], global_arm['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on ARM eu-central-1\n")
    welchs_ttest(df_eu_central_arm['total runtime (ms)'], global_arm['total runtime (ms)'])
    print('-------------------------------------------------------------')
    print("Welch's t-test on ARM ap-northeast-1\n")
    welchs_ttest(df_ap_ne_arm['total runtime (ms)'], global_arm['total runtime (ms)'])
    print('-------------------------------------------------------------')
    
    print("Student's t-test for architecture comparison (all regions)\n")
    print(stats.ttest_ind(global_x86['total runtime (ms)'], global_arm['total runtime (ms)'])[1])
    print('-------------------------------------------------------------')
    
    print('All x86 average:', avg_runtime_x86, '\nAll ARM average', avg_runtime_arm)
    print('x86 avg / ARM avg:', avg_runtime_x86/avg_runtime_arm)
    print('-------------------------------------------------------------')
    #3am-7am
    print("3am to 7am average runtime\n")
    print("x86:",global_x86[14:34]['total runtime (ms)'].mean())
    #print(global_arm[14:34]['start time'])
    print("ARM:",global_arm[14:34]['total runtime (ms)'].mean())
    
    #2pm-6pm
    print("\n2pm to 7pm average runtime\n")
    print("x86:",global_x86[65:85]['total runtime (ms)'].mean())
    #print(global_x86[65:85]['start time'])
    print("ARM:",global_arm[65:84]['total runtime (ms)'].mean())
    
    print('-------------------------------------------------------------')
    global_x86['start time'] = global_x86['start time'].apply(lambda x: convert_to_hour(x))
    global_arm['start time'] = global_arm['start time'].apply(lambda x: convert_to_hour(x))
    print("Average x86 runtime across two-hour blocks:")
    print(global_x86[['start time', 'total runtime (ms)']].groupby('start time').mean().reset_index())
    print("\nAverage ARM runtime across two-hour blocks:")
    print(global_arm[['start time', 'total runtime (ms)']].groupby('start time').mean().reset_index())
# =============================================================================
# =============================================================================
# #     TODO:
# #         percent differnce at function level: all ARM vs all x86 (3 comparisons)
# #         percent diff at func lvl: regions (24 comparisons)
# =============================================================================
# =============================================================================
# =============================================================================
#     linear_regr(global_x86, 'globalx86')
#     linear_regr(df_us_west_x86, 'uswest')
#     linear_regr(df_us_east_x86, 'useast')
#     linear_regr(df_ap_ne_x86, 'asia')
#     linear_regr(df_eu_central_x86, 'eu')
# =============================================================================
    
if __name__ == '__main__':
    main()