import { ConnectWallet } from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";
import Image from "next/image";

export default function Home() {
  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.header}>
          <h1 className={styles.title}>
            Welcome to Ravdesk
          </h1>

         

          <div className={styles.connect}>
            <ConnectWallet
              dropdownPosition={{
                side: "bottom",
                align: "right",
              }}
            />
            
          </div>
        </div>

       

          
          
        
      </div>
    </main>
  );
}
