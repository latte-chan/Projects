/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Aidan-WC
 */
public class Flight 
{
    private String name;
    private int seats;
    
    public Flight(String name, int seats)
    {
        this.name = name;
        this.seats = seats;
    }

    public String getName() 
    {
        return name;
    }
    public void setName(String name) 
    {
        this.name = name;
    }

    public int getSeats()
    {
        return seats;
    }
    public void setSeats(int seats)
    {
        this.seats = seats;
    }
}
