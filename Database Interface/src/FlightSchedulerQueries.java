
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Aidan-WC
 */
public class FlightSchedulerQueries 
{
    private DBConnection dbConnection;
    private PreparedStatement insertNewCustomer;
    private PreparedStatement selectAllCustomers;
    private PreparedStatement insertNewFlight;
    private PreparedStatement selectAllFlights;
    private PreparedStatement findFlightSeats;
    private PreparedStatement changeFlightSeats;
    private PreparedStatement removeFlight;
    private PreparedStatement insertNewDay;
    private PreparedStatement selectAllDays;
    private PreparedStatement insertNewBooking;
    private PreparedStatement selectAllBookings;
    private PreparedStatement selectCustomerBookings;
    private PreparedStatement selectCustomerDayBookings;
    private PreparedStatement selectFlightDayBookings;
    private PreparedStatement insertNewWaitBooking;
    private PreparedStatement selectAllWaitBookings;
    private PreparedStatement selectCustomerWaitBookings;
    private PreparedStatement selectCustomerDayWaitBookings;
    private PreparedStatement selectDayWaitBookings;
    private PreparedStatement selectFlightWaitBookings;
    private PreparedStatement selectFlightDayWaitBookings;
    private PreparedStatement removeCustomerDayBooking;
    private PreparedStatement removeCustomerDayWaitBooking;
    private PreparedStatement removeFlightDayWaitBookings;
    
    public FlightSchedulerQueries()
    {
        dbConnection = new DBConnection();
        try
        {
            insertNewCustomer = dbConnection.getConnection().prepareStatement("INSERT INTO Customers (Name) VALUES (?)");
            selectAllCustomers = dbConnection.getConnection().prepareStatement("SELECT * FROM Customers");
            insertNewFlight = dbConnection.getConnection().prepareStatement("INSERT INTO Flight (Name, Seats) VALUES (?, ?)");
            selectAllFlights = dbConnection.getConnection().prepareStatement("SELECT * FROM Flight");
            findFlightSeats = dbConnection.getConnection().prepareStatement("SELECT Seats FROM Flight WHERE Name = ?");
            changeFlightSeats = dbConnection.getConnection().prepareStatement("UPDATE Flight SET Seats = ? WHERE Name = ?");
            removeFlight = dbConnection.getConnection().prepareStatement("DELETE FROM Flight WHERE Name = ?");
            insertNewDay = dbConnection.getConnection().prepareStatement("INSERT INTO Day (Date) VALUES (?)");
            selectAllDays = dbConnection.getConnection().prepareStatement("SELECT * FROM Day");
            insertNewBooking = dbConnection.getConnection().prepareStatement("INSERT INTO Bookings (Name, Flight, Day, Timestamp) VALUES(?, ?, ?, ?)");
            selectAllBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Bookings");
            selectCustomerBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Bookings WHERE Name = ?");
            selectCustomerDayBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Bookings WHERE Name = ? and Day = ?");
            selectFlightDayBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Bookings WHERE Flight = ? and Day = ?");
            insertNewWaitBooking = dbConnection.getConnection().prepareStatement("INSERT INTO Waitlist (Name, Flight, Day, Timestamp) VALUES(?, ?, ?, ?)");
            selectAllWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist");
            selectCustomerWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist WHERE Name = ?");
            selectCustomerDayWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist WHERE Name = ? and Day = ?");
            selectDayWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist WHERE Day = ?");
            selectFlightWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist WHERE Flight = ?");
            selectFlightDayWaitBookings = dbConnection.getConnection().prepareStatement("SELECT * FROM Waitlist WHERE Flight = ? and Day = ?");
            removeCustomerDayBooking = dbConnection.getConnection().prepareStatement("DELETE FROM Bookings WHERE Name = ? and Day = ?");
            removeCustomerDayWaitBooking = dbConnection.getConnection().prepareStatement("DELETE FROM Waitlist WHERE Name = ? and Day = ?");
            removeFlightDayWaitBookings = dbConnection.getConnection().prepareStatement("DELETE FROM Waitlist WHERE Flight = ? and Day = ?");
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    public void addCustomer(String textName)
    {
        try
        {
            insertNewCustomer.setString(1, textName);
            
            insertNewCustomer.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public List<Customer> getCustomers()
    {
        List<Customer> results = null;
        ResultSet resultSet = null;
        
        try
        {
            resultSet = selectAllCustomers.executeQuery();
            results = new ArrayList<Customer>();
            
            while(resultSet.next())
            {
                results.add(new Customer(resultSet.getString("Name")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        return results;
    }
    
    public List<String> getCustomerNames()
    {
        List<String> results = null;
        results = new ArrayList<String>();
        List<Customer> customers = getCustomers();
        for(Customer currentC : customers)
        {
            results.add(currentC.getName());
        }
        return results;
    }
    
    public void addFlight(String name, int seats)
    {
        try
        {
            insertNewFlight.setString(1, name);
            insertNewFlight.setString(2, String.valueOf(seats));
            
            insertNewFlight.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public List<Flight> getFlights()
    {
        List<Flight> results = null;
        ResultSet resultSet = null;
        
        try
        {
            resultSet = selectAllFlights.executeQuery();
            results = new ArrayList<Flight>();
            
            while(resultSet.next())
            {
                results.add(new Flight(resultSet.getString("Name"), Integer.valueOf(resultSet.getString("Seats"))));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<String> getFlightNames()
    {
        List<String> results = null;
        results = new ArrayList<String>();
        List<Flight> flights = getFlights();
        
        for(Flight currentF : flights)
        {
            results.add(currentF.getName());
        }
        
        return results;
    }
    
    public List<String> getAllFlightSeats()
    {
        List<String> results = null;
        results = new ArrayList<String>();
        List<Flight> flights = getFlights();
        
        for(Flight currentF : flights)
        {
            results.add(String.valueOf(currentF.getSeats()));
        }
        
        return results;
    }
    
    public int getFlightSeats(String name)
    {
        int flightSeats = 0;
        ResultSet resultSet = null;
        
        try
        {
            findFlightSeats.setString(1, name);
            
            resultSet = findFlightSeats.executeQuery();
            
            while(resultSet.next())
            {
                flightSeats = Integer.valueOf(resultSet.getString("Seats"));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return flightSeats;
    }
    
    public void setFlightSeats(String name, int seats)
    {
        try
        {
            changeFlightSeats.setString(1, String.valueOf(seats));
            changeFlightSeats.setString(2, name);
            
            changeFlightSeats.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public void deleteFlight(String flight)
    {
        try
        {
            removeFlight.setString(1, flight);
            
            removeFlight.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public void addDay(Day day)
    {
        Date date = day.getDate();
        
        try
        {
            insertNewDay.setString(1, String.valueOf(date));
            
            insertNewDay.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public List<Day> getDays()
    {
        List<Day> results = null;
        ResultSet resultSet = null;
        
        try
        {
            resultSet = selectAllDays.executeQuery();
            results = new ArrayList<Day>();
            
            while(resultSet.next())
            {
                results.add(new Day(resultSet.getDate("Date")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<String> getDayDates()
    {
        List<String> results = null;
        results = new ArrayList<String>();
        List<Day> days = getDays();
        
        for(Day currentD : days)
        {
            results.add(String.valueOf(currentD.getDate()));
        }
        
        return results;
    }
    
    public void addBooking(String name, String flight, String date)
    {
        try
        {
            Timestamp currentTimestamp = new Timestamp(Calendar.getInstance().getTime().getTime());
            
            insertNewBooking.setString(1, name);
            insertNewBooking.setString(2, flight);
            insertNewBooking.setString(3, date);
            insertNewBooking.setTimestamp(4, currentTimestamp);
            
            insertNewBooking.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public List<BookingEntry> getBookings()
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            resultSet = selectAllBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> getCustomerBookings(String name)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectCustomerBookings.setString(1, name);
            
            resultSet = selectCustomerBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> getFlightDayBookings(String flight, String day)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectFlightDayBookings.setString(1, flight);
            selectFlightDayBookings.setString(2, day);
            
            resultSet = selectFlightDayBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public void addWaitBooking(String name, String flight, String date)
    {
        try
        {
            Timestamp currentTimestamp = new Timestamp(Calendar.getInstance().getTime().getTime());
            
            insertNewWaitBooking.setString(1, name);
            insertNewWaitBooking.setString(2, flight);
            insertNewWaitBooking.setString(3, date);
            insertNewWaitBooking.setTimestamp(4, currentTimestamp);
            
            insertNewWaitBooking.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
            close();
        }
    }
    
    public List<BookingEntry> getWaitBookings()
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            resultSet = selectAllWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> getCustomerWaitBookings(String name)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectCustomerWaitBookings.setString(1, name);
            
            resultSet = selectCustomerWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> getDayWaitBookings(String day)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectDayWaitBookings.setString(1, day);
            
            resultSet = selectDayWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> getFlightWaitBookings(String flight)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectFlightWaitBookings.setString(1, flight);
            
            resultSet = selectFlightWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> deleteCustomerDayBooking(String name, String day)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectCustomerDayBookings.setString(1, name);
            selectCustomerDayBookings.setString(2, day);
            removeCustomerDayBooking.setString(1, name);
            removeCustomerDayBooking.setString(2, day);
            
            resultSet = selectCustomerDayBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
            
            removeCustomerDayBooking.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> deleteCustomerDayWaitBooking(String name, String day)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectCustomerDayWaitBookings.setString(1, name);
            selectCustomerDayWaitBookings.setString(2, day);
            removeCustomerDayWaitBooking.setString(1, name);
            removeCustomerDayWaitBooking.setString(2, day);
            
            resultSet = selectCustomerDayWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
            
            removeCustomerDayWaitBooking.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public List<BookingEntry> deleteFlightDayWaitBookings(String flight, String day)
    {
        List<BookingEntry> results = null;
        ResultSet resultSet = null;
        
        List<Flight> flightList = getFlights();
        
        Customer c;
        Flight f = null;
        Day d;
        
        try
        {
            selectFlightDayWaitBookings.setString(1, flight);
            selectFlightDayWaitBookings.setString(2, day);
            removeFlightDayWaitBookings.setString(1, flight);
            removeFlightDayWaitBookings.setString(2, day);
            
            resultSet = selectFlightDayWaitBookings.executeQuery();
            results = new ArrayList<BookingEntry>();
            
            while(resultSet.next())
            {
                c = new Customer(resultSet.getString("Name"));
                for(Flight currentF: flightList)
                {
                    if(resultSet.getString("Flight").equals(currentF.getName()))
                    {
                        f = new Flight(resultSet.getString("Flight"), currentF.getSeats());
                        break;
                    }
                }
                d = new Day(resultSet.getDate("Day"));
                results.add(new BookingEntry(c, f, d, resultSet.getTimestamp("Timestamp")));
            }
            
            removeFlightDayWaitBookings.executeUpdate();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
        finally
        {
            try
            {
                resultSet.close();
            }
            catch(SQLException e)
            {
                e.printStackTrace();
                close();
            }
        }
        
        return results;
    }
    
    public void close()
    {
        try
        {
            dbConnection.getConnection().close();
        }
        catch(SQLException e)
        {
            e.printStackTrace();
        }
    }
}
