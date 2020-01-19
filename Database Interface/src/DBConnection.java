
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Aidan-WC
 */
public class DBConnection 
{
    private Connection connection;
    
    private static final String URL = "jdbc:derby://localhost:1527/FlightSchedulerDBAidanArj5190";
    private static final String USERNAME = "java";
    private static final String PASSWORD = "java";
    
    public DBConnection()
    {
        try
        {
            connection = DriverManager.getConnection(URL, USERNAME, PASSWORD);
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    public Connection getConnection()
    {
        return connection;
    }
}
