function plot_validation_maneuvers(plot_title, simulation_data_for_plotting, model_type, model_names, plot_styles, model_names_to_display)
    set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex');

    num_maneuvers = numel(simulation_data_for_plotting);
    num_models = length(model_names);
    
    dt = simulation_data_for_plotting{1}.Time(2) - simulation_data_for_plotting{1}.Time(1);
    rec_data = [];
    input = [];
    maneuver_start_index = zeros(num_maneuvers + 1, 1);
    
    model_data = {};
    for model_i = 1:num_models
        model_data.(model_names(model_i)) = [];
    end
    
    for maneuver_i = 1:num_maneuvers
        rec_data = [rec_data; simulation_data_for_plotting{maneuver_i}.RecordedData];
        maneuver_length = length(simulation_data_for_plotting{maneuver_i}.Time);
        input = [input; simulation_data_for_plotting{maneuver_i}.Input];
        maneuver_start_index(maneuver_i + 1) = maneuver_start_index(maneuver_i) + maneuver_length;
        for model_i = 1:num_models
            model_data.(model_names(model_i)) = [model_data.(model_names(model_i)); simulation_data_for_plotting{maneuver_i}.Models.(model_names(model_i))];
        end
    end
    maneuver_start_index = maneuver_start_index(2:end-1,:);
    
    N = length(rec_data);
    time = 0:dt:N*dt-dt;
    
    font_size_large = 20;
    font_size = 16;
    font_size_small = 14;
    line_width = 1.5;
    plot_style_recorded_data =  "--";
    target_color = [0, 0, 0, 0.5];
    
    if strcmp(model_type, "longitudinal")
        fig = figure;
        fig.Position = [100 100 1000 800];
        num_plots_rows = 5;
        num_models = numel(model_names);
        t = tiledlayout(num_plots_rows,1, 'Padding', 'compact', 'TileSpacing', 'compact'); 

        nexttile
        for i = 1:num_models
            plot(time, model_data.(model_names(i))(:,1), 'LineWidth',line_width); hold on
        end
        grid on
        grid minor
        plot(time, rec_data(:,1), plot_style_recorded_data, 'LineWidth',line_width, 'Color', target_color); hold on;
        plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
        set(gca,'FontSize', font_size_small)
        ylabel("$u [m/s]$", 'interpreter', 'latex', 'FontSize', font_size)
        ylim([0 28])
        xlim([0 time(end)]);
        set(gca,'xtick',[])

        nexttile
        for i = 1:num_models
            plot(time, model_data.(model_names(i))(:,2), 'LineWidth',line_width); hold on
        end
        grid on
        grid minor
        plot(time, rec_data(:,2), plot_style_recorded_data, 'LineWidth',line_width, 'Color', target_color); hold on
        plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
        set(gca,'FontSize', font_size_small)
        ylabel("$w [m/s]$", 'interpreter', 'latex', 'FontSize', font_size)
        ylim([-10 10])
        xlim([0 time(end)]);
        set(gca,'xtick',[])

        nexttile
        for i = 1:num_models
            plot(time, rad2deg(model_data.(model_names(i))(:,3)), 'LineWidth',line_width); hold on
        end
        grid on
        grid minor
        plot(time, rad2deg(rec_data(:,3)), plot_style_recorded_data, 'LineWidth',line_width, 'Color', target_color); hold on
        plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
        set(gca,'FontSize', font_size_small)
        ylim([-200 200]);
        xlim([0 time(end)]);
        set(gca,'xtick',[])
        ylabel("$q [\circ/s]$", 'interpreter', 'latex', 'FontSize', font_size)

        nexttile
        for i = 1:num_models
            plot(time, rad2deg(model_data.(model_names(i))(:,4)), 'LineWidth',line_width); hold on
        end
        grid on
        grid minor
        plot(time, rad2deg(rec_data(:,4)), plot_style_recorded_data, 'LineWidth',line_width, 'Color', target_color); hold on
        plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
        set(gca,'FontSize', font_size_small)
        ylabel("$\theta [\circ]$", 'interpreter', 'latex', 'FontSize', font_size)
        ylim([-70 70])
        xlim([0 time(end)]);
        lgd = legend([model_names_to_display "Recorded Data"], 'location', 'southeast', 'FontSize', font_size_small);
        

        nexttile
        plot(time, rad2deg(input(:,1)), 'black', 'LineWidth', line_width); hold on
        grid on
        grid minor
        plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
        set(gca,'FontSize', font_size_small)
        ylabel("$\delta_e [\circ]$", 'interpreter', 'latex', 'FontSize', font_size)
        ylim([-32 32])
        %title("Input", 'FontSize', font_size, 'interpreter', 'latex')
        xlim([0 time(end)]);
        lgd = legend("Input", 'location', 'southeast', 'FontSize', font_size_small);
        
        title(t, plot_title, 'FontSize', font_size_large, 'interpreter', 'latex')
        xlabel(t, "Time $[s]$", 'interpreter', 'latex', 'FontSize', font_size)
        
              
%
        
%         subplot(num_plots_rows,1,4)
%         plot(time, input(:,2)); hold on
%         plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
%         legend("$\delta_t$");
%         ylabel("[rev/s]")
%         ylim([0 150])
%         title("Throttle")
%         
    end
end

function plot_maneuver_lines(maneuver_start_index, num_maneuvers, time)
    for maneuver_i = 1:num_maneuvers-1
        xline(time(maneuver_start_index(maneuver_i)),"--"); hold on
    end
end