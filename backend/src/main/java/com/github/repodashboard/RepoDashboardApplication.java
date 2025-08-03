package com.github.repodashboard;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class RepoDashboardApplication {

    public static void main(String[] args) {
        SpringApplication.run(RepoDashboardApplication.class, args);
    }
}