
import java.sql.Timestamp;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Aidan-WC
 */
public class BookingEntry 
{
    private Customer customer;
    private Flight flight;
    private Day day;
    private Timestamp time;
    
    public BookingEntry(Customer customer, Flight flight, Day day, Timestamp time)
    {
        this.customer = customer;
        this.flight = flight;
        this.day = day;
        this.time = time;
    }

    public Customer getCustomer() 
    {
        return customer;
    }
    public void setCustomer(Customer customer) 
    {
        this.customer = customer;
    }

    public Flight getFlight() 
    {
        return flight;
    }
    public void setFlight(Flight flight)
    {
        this.flight = flight;
    }

    public Day getDay() 
    {
        return day;
    }
    public void setDay(Day day)
    {
        this.day = day;
    }

    public Timestamp getTime() 
    {
        return time;
    }
    public void setTime(Timestamp time)
    {
        this.time = time;
    }
    
    @Override
    public boolean equals(Object o)
    {
        if(o instanceof BookingEntry)
        {
            BookingEntry b = (BookingEntry) o;
            if(flight.getName().equals(b.getFlight().getName()) && day.getDate().equals(b.getDay().getDate()))
                return true;
        }
        return false;
    }
}
